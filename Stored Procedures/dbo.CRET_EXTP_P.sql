SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Batch submitted through debugger: SQLQuery18.sql|7|0|C:\Users\Aref\AppData\Local\Temp\~vs498E.sql
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CRET_EXTP_P]
	-- Add the parameters for the stored procedure here
	@RqrqCode BIGINT = NULL,
	@EpitCode BIGINT = NULL
AS
BEGIN
   DECLARE @RqtpCode VARCHAR(3)
          ,@RqttCode VARCHAR(3)
          ,@RqtpEpitType VARCHAR(3)
          ,@EpitType VARCHAR(3);
   
	DECLARE C$RequestRequester CURSOR FOR
	   SELECT rr.Code, Rq.EPIT_TYPE FROM Request_Requester rr, Regulation rg, dbo.Request_Type Rq
	    WHERE ((@RqrqCode IS NULL) OR (rr.Code = @RqrqCode))
	      AND rr.Regl_Year = rg.[Year]
	      AND rr.Regl_Code = rg.Code
	      AND rr.RQTP_CODE = Rq.CODE
	      AND rg.[Type] = '001'
	      AND rg.Regl_Stat = '002';
	
	DECLARE C$ExpenseItem CURSOR FOR
	   SELECT Code, Rqtp_Code, Rqtt_Code, [Type] FROM Expense_Item
	    WHERE [Type] IN ( '001' , '003' )
	      AND ((@EpitCode IS NULL) OR (Code = @EpitCode));
	
	OPEN C$RequestRequester;
	L$NextRqrqRow:
	FETCH NEXT FROM C$RequestRequester INTO @RqrqCode, @RqtpEpitType;
	
	IF @@FETCH_STATUS <> 0
	   GOTO L$EndRqrqFetch;
	
	   OPEN C$ExpenseItem;
	   L$NextEpitRow:
	   FETCH NEXT FROM C$ExpenseItem INTO @EpitCode, @RqtpCode, @RqttCode, @EpitType;
	   
	   IF @@FETCH_STATUS <> 0
	      GOTO L$EndEpitFetch;
	   
	   IF @RqtpEpitType != @EpitType
	      GOTO L$NextEpitRow;
	   
	   IF NOT EXISTS(
	      SELECT *
	        FROM Request_Requester
	       WHERE CODE = @RqrqCode
	         AND (@RqtpCode IS NULL OR RQTP_CODE = @RqtpCode)
	         AND (@RqttCode IS NULL OR RQTT_CODE = @RqttCode)
	   )
	      GOTO L$NextEpitRow;
	   
	   IF NOT EXISTS(
	      SELECT *
	        FROM Expense_Type
	       WHERE RQRQ_CODE = @RqrqCode
	         AND EPIT_CODE = @EpitCode
	         /*AND ( @RqtpCode IS NULL 
	            OR EXISTS(
	                  SELECT *
	                    FROM Request_Requester
	                   WHERE CODE = @RqrqCode
	                     AND RQTP_CODE = @RqtpCode
	               )
	            )
	         AND ( @RqttCode IS NULL 
	            OR EXISTS(
	                  SELECT *
	                    FROM Request_Requester
	                   WHERE CODE = @RqrqCode
	                     AND RQTT_CODE = @RqttCode
	               )
	            )*/
	   )
	   BEGIN
	      INSERT INTO Expense_Type (RQRQ_CODE, EPIT_CODE)
	      VALUES(@RqrqCode, @EpitCode);
	   END
	      
	   GOTO L$NextEpitRow;
	   L$EndEpitFetch:
	   CLOSE C$ExpenseItem;
	
	GOTO L$NextRqrqRow;	
	L$EndRqrqFetch:
	CLOSE C$RequestRequester;
	DEALLOCATE C$RequestRequester;
	DEALLOCATE C$ExpenseItem;
END
GO
