SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[COPY_RQRQ_P]
   @ReglYear SMALLINT,
   @ReglCode INT,
	@RqtpCode VARCHAR(3) = NULL,
	@RqttCode VARCHAR(3) = NULL
AS
BEGIN
	DECLARE C$COPYRQRQREGL CURSOR FOR
	   SELECT YEAR, CODE FROM dbo.Regulation
	   WHERE Year = @ReglYear
	     AND Code = @ReglCode;
   -- ايجاى يه وقفه كوتاه براي آیین نامه جدید و قدیم
   DECLARE @OldReglYear SMALLINT
          ,@OldReglCode INT;
   SELECT @OldReglYear = YEAR
         ,@OldReglCode = CODE
     FROM Regulation
    WHERE REGL_STAT = '002'
      AND TYPE = (SELECT TYPE FROM Regulation WHERE YEAR = @ReglYear AND CODE = @ReglCode);
   
   UPDATE Regulation
      SET REGL_STAT = '001'   
    WHERE YEAR = @OldReglYear
      AND CODE = @OldReglCode;
   
   UPDATE Regulation
      SET REGL_STAT = '002'   
    WHERE YEAR = @ReglYear
      AND CODE = @ReglCode;      
      
   DECLARE C$RequestType CURSOR FOR
      SELECT CODE FROM Request_Type
       WHERE ((@RqtpCode IS NULL) OR (Code = @RqtpCode));
   
   DECLARE C$RequesterType CURSOR FOR
      SELECT CODE FROM Requester_Type 
       WHERE ((@RqttCode IS NULL) OR (Code = @RqttCode));
      
	OPEN C$COPYRQRQREGL;
	L$NextReglRow:
	FETCH NEXT FROM C$COPYRQRQREGL INTO @ReglYear, @ReglCode;
	
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
	CLOSE C$COPYRQRQREGL;

	DEALLOCATE C$COPYRQRQREGL;
   DEALLOCATE C$RequestType;
   DEALLOCATE C$RequesterType;
   
   -- بازکشت آیین نامه قدیم به حالت فعال

   UPDATE Regulation
      SET REGL_STAT = '001'
    WHERE YEAR IN ( @ReglYear )
      AND CODE IN ( @ReglCode );      

   
   UPDATE Regulation
      SET REGL_STAT = '002'
    WHERE YEAR IN ( @OldReglYear )
      AND CODE IN ( @OldReglCode );
      
   EXEC SYNC_RGL1_P @ReglYear, @ReglCode, @OldReglYear, @OldReglCode;
END
GO
