SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CRET_RQRQ_P]
	@RqtpCode VARCHAR(3) = NULL,
	@RqttCode VARCHAR(3) = NULL
AS
BEGIN
	DECLARE C$CreateRegulation CURSOR FOR
	   SELECT YEAR, CODE FROM dbo.Regulation
	   WHERE REGL_STAT = '002' -- فعال
	     AND TYPE = '001' -- هزینه
	   ;

   DECLARE C$RequestType CURSOR FOR
      SELECT CODE FROM Request_Type
       WHERE ((@RqtpCode IS NULL) OR (Code = @RqtpCode));
   
   DECLARE C$RequesterType CURSOR FOR
      SELECT CODE FROM Requester_Type 
       WHERE ((@RqttCode IS NULL) OR (Code = @RqttCode));
	       	
	DECLARE @ReglYear SMALLINT
	       ,@ReglCode INT;
	       
	OPEN C$CreateRegulation;
	L$NextReglRow:
	FETCH NEXT FROM C$CreateRegulation INTO @ReglYear, @ReglCode;
	
	IF @@FETCH_STATUS <> 0 
	   GOTO L$EndReglFetch;
	       
	   OPEN C$RequestType;
	   L$NextRqtpRow:
	   FETCH NEXT FROM C$RequestType INTO @RqtpCode;
	   
	   IF @@FETCH_STATUS <> 0
	      GOTO L$EndRqtpFetch;
	   
	      OPEN C$RequesterType;
	      L$NextRqttRow:
	      FETCH NEXT FROM C$RequesterType INTO @RqttCode;
	      
	      IF @@FETCH_STATUS <> 0
	         GOTO L$EndRqttFetch;
	      
	      -- START MAIN CODE
	      IF NOT EXISTS(
	         SELECT *
	           FROM Request_Requester
	          WHERE REGL_CODE = @ReglCode
	            AND REGL_YEAR = @ReglYear
	            AND RQTP_CODE = @RqtpCode
	            AND RQTT_CODE = @RqttCode
	      )
	      BEGIN	         
	         INSERT INTO Request_Requester (REGL_CODE, REGL_YEAR, RQTP_CODE, RQTT_CODE, SUB_SYS, PERM_STAT)
	         VALUES (@ReglCode, @ReglYear, @RqtpCode, @RqttCode, 1, '001');
	      END
	      -- END MAIN CODE
	      
	      GOTO L$NextRqttRow;
	      L$EndRqttFetch:
	      CLOSE C$RequesterType;	     
	   
	   GOTO L$NextRqtpRow;
	   L$EndRqtpFetch:
	   CLOSE C$RequestType;

	   
	GOTO L$NextReglRow;
	L$EndReglFetch:
	CLOSE C$CreateRegulation;

	DEALLOCATE C$CreateRegulation;
   DEALLOCATE C$RequestType;
   DEALLOCATE C$RequesterType;
	   
END
GO
