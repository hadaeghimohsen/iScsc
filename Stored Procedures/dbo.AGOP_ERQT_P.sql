SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mohsen Hadaeghi
-- Create date: 1395/07/11
-- Description:	
-- =============================================
CREATE PROCEDURE [dbo].[AGOP_ERQT_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
   BEGIN TRY
   BEGIN TRANSACTION T$AGOP_ERQT_P
	DECLARE @AgopCode BIGINT
	       ,@FileNo BIGINT
	       ,@OprtType VARCHAR(3)
	       ,@PrvnCode VARCHAR(3)
	       ,@RegnCode VARCHAR(3)
	       ,@RqttCode VARCHAR(3)
	       ,@FromDate DATE
	       ,@ToDate DATE
	       ,@CochFileNo BIGINT
	       ,@NumbMontOfer INT
	       ,@NewCbmtCode BIGINT
	       ,@NewMtodCode BIGINT
	       ,@NewCtgyCode BIGINT
	       ,@AttnType VARCHAR(3)
	       ,@RqstRqid BIGINT;
	
	SELECT @AgopCode = @X.query('//Aodt').value('(Aodt/@agopcode)[1]'    , 'BIGINT')
	      ,@FileNo = @X.query('//Aodt').value('(Aodt/@fighfileno)[1]'    , 'BIGINT');
	
	SELECT @OprtType = OPRT_TYPE, @RqttCode = RQTT_CODE, @FromDate = FROM_DATE, @ToDate = TO_DATE, @NumbMontOfer = NUMB_MONT_OFFR, @NewCbmtCode = NEW_CBMT_CODE, @NewMtodCode = NEW_MTOD_CODE, @NewCtgyCode = NEW_CTGY_CODE FROM dbo.Aggregation_Operation WHERE code = @agopcode;
	SELECT @RegnCode = REGN_CODE, @PrvnCode = REGN_PRVN_CODE FROM dbo.Fighter WHERE FILE_NO = @FileNo;
	
	IF @OprtType = '001' -- تمدید گروهی
	BEGIN
      SELECT @RqstRqid = F.RQST_RQID
        FROM Fighter F
       WHERE F.FILE_NO = @FileNo;
      
  	   SET @X = '<Process><Request rqid=""><Payment setondebt="1"/></Request></Process>';
  	   SET @X.modify('replace value of (/Process/Request/@rqid)[1] with sql:variable("@RqstRqid")');
      
      EXEC UCC_TSAV_P @X;            
	END
	ELSE IF @OprtType = '002' -- تغییر ساعت کلاسی
	BEGIN
	   SELECT @X = (
	      SELECT R.RQID AS '@rqid'
	            ,R.REGN_CODE AS '@regncode'
	            ,R.REGN_PRVN_CODE AS '@prvncode'
               ,(
                  SELECT 
                     F.File_No AS '@fileno'                     
                  FOR XML PATH('Request_Row'), TYPE 
               )
               FROM Request R, dbo.Fighter F
              WHERE R.Rqid = F.RQST_RQID  
                AND F.FILE_NO = @FileNo            
            FOR XML PATH('Request'), ROOT('Process'), TYPE
	   )	 
	   EXEC dbo.PBL_SAVE_F @X = @X; -- xml	        
	END
	ELSE IF @OprtType = '003' -- تغییر سبک و رسته گروهی
	BEGIN
	   SELECT @X = (
	      SELECT R.Rqid AS '@rqid'
               ,'011' AS '@rqtpcode'
               ,'004' AS '@rqttcode'
               ,(
                  SELECT 
                     @FileNo AS '@fileno',
                     (
                     SELECT 
                        @NewMtodCode AS 'Mtod_Code',
                        @NewCtgyCode AS 'Ctgy_Code'
                     FOR XML PATH('ChngMtodCtgy'), TYPE 
                     )
                  FOR XML PATH('Request_Row'), TYPE 
               )
            FROM Request R, dbo.Fighter F
            WHERE R.RQID = F.RQST_RQID
              AND F.FILE_NO = @FileNo            
            FOR XML PATH('Request'), ROOT('Process'), TYPE
	   )	 
	   EXEC dbo.CMC_SAVE_F @X = @X -- xml
	   
	   UPDATE dbo.Fighter_Public
	      SET CBMT_CODE = @NewCbmtCode
	    WHERE FIGH_FILE_NO = @FileNo
	      AND RECT_CODE = '004'
	      AND RWNO = (SELECT FGPB_RWNO_DNRM FROM dbo.Fighter WHERE FILE_NO = @FileNo);
	END
	ELSE IF @OprtType = '004' -- ثبت حضور و غیاب
	BEGIN
	   SELECT @AttnType = ATTN_TYPE
	         ,@CochFileNo = COCH_FILE_NO
	     FROM dbo.Aggregation_Operation_Detail
	    WHERE AGOP_CODE = @AgopCode
	      AND FIGH_FILE_NO = @FileNo;	
	   
	   EXEC dbo.INS_ATTN_P @Club_Code = NULL, -- bigint
	       @Figh_File_No = @FileNo, -- bigint
	       @Attn_Date = @FromDate, -- date
	       @CochFileNo = @CochFileNo, -- bigint
	       @Attn_TYPE = @AttnType; -- varchar(3)
	   
	   UPDATE dbo.Aggregation_Operation_Detail
	      SET ATTN_CODE = (SELECT MAX(Code) from dbo.Attendance WHERE FIGH_FILE_NO = @FileNo AND ATTN_DATE = @FromDate AND ATTN_TYPE = @AttnType AND CRET_BY = UPPER(SUSER_NAME()))
	    WHERE AGOP_CODE = @AgopCode
	      AND FIGH_FILE_NO = @FileNo;
	END
	ELSE IF @OprtType = '005' -- ثبت هزینه میز و بوفه
	BEGIN
	   DECLARE C$FighRecStat002Stat001 CURSOR FOR
	      SELECT AGOP_CODE
	            ,RWNO
	            ,FIGH_FILE_NO
	        FROM dbo.Aggregation_Operation_Detail
	       WHERE REC_STAT = '002'
	         AND STAT = '001'
	         AND AGOP_CODE = @AgopCode;
	   
	   DECLARE @Rwno INT;
	   
	   OPEN C$FighRecStat002Stat001;
	   L$O$C$FighRecStat002Stat001:
	   FETCH NEXT FROM C$FighRecStat002Stat001 INTO @AgopCode, @Rwno, @FileNo;
	   
	   IF @@FETCH_STATUS <> 0
	      GOTO L$C$C$FighRecStat002Stat001;
	   
	   SELECT @X = (
	      SELECT @AgopCode AS '@agopcode'
	            ,@rwno AS '@rwno'
	            ,@FileNo AS '@fileno'
	         FOR XML PATH('Aggregation_Operation_Detail'), TYPE
	   );
	   
	   EXEC dbo.ENDO_RSBU_P @X = @X -- xml	   
	      
	   GOTO L$O$C$FighRecStat002Stat001
	   L$C$C$FighRecStat002Stat001:
	   CLOSE C$FighRecStat002Stat001;
	   DEALLOCATE C$FighRecStat002Stat001;
	END
	
	COMMIT TRANSACTION T$AGOP_ERQT_P;
	END TRY
	BEGIN CATCH
	   DECLARE @ErrorMessage NVARCHAR(MAX);
	   SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T$AGOP_ERQT_P;
	END CATCH;	
END
GO
