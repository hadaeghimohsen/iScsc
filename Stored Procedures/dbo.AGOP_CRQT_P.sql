SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mohsen Hadaeghi
-- Create date: 1395/07/11
-- Description:	
-- =============================================
CREATE PROCEDURE [dbo].[AGOP_CRQT_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
   BEGIN TRY
   BEGIN TRANSACTION T$AGOP_CRQT_P
	DECLARE @AgopCode BIGINT
	       ,@Rwno INT
	       ,@FileNo BIGINT
	       ,@OprtType VARCHAR(3)
	       ,@PrvnCode VARCHAR(3)
	       ,@RegnCode VARCHAR(3)
	       ,@RqttCode VARCHAR(3)
	       ,@FromDate DATE
	       ,@ToDate DATE
	       ,@NumbMontOfer INT
	       ,@NumbOfAttnMont INT
	       ,@MtodCodeDnrm BIGINT
	       ,@CtgyCodeDnrm BIGINT
	       ,@CbmtCodeDnrm BIGINT
	       ,@NewCbmtCode BIGINT
	       ,@NewMtodCode BIGINT
	       ,@NewCtgyCode BIGINT
	       ,@RqstRqid BIGINT;
	
	SELECT @AgopCode = @X.query('//Aodt').value('(Aodt/@agopcode)[1]'    , 'BIGINT')
	      ,@FileNo = @X.query('//Aodt').value('(Aodt/@fighfileno)[1]'    , 'BIGINT')
	      ,@Rwno = @X.query('//Aodt').value('(Aodt/@rwno)[1]'    , 'INT');
	
	SELECT @OprtType = OPRT_TYPE, @RqttCode = RQTT_CODE, @FromDate = FROM_DATE, @ToDate = TO_DATE, @NumbMontOfer = NUMB_MONT_OFFR, @NumbOfAttnMont = NUMB_OF_ATTN_MONT, @NewCbmtCode = NEW_CBMT_CODE, @NewMtodCode = NEW_MTOD_CODE, @NewCtgyCode = NEW_CTGY_CODE FROM dbo.Aggregation_Operation WHERE code = @agopcode;
	SELECT @RegnCode = REGN_CODE, @PrvnCode = REGN_PRVN_CODE, @MtodCodeDnrm = MTOD_CODE_DNRM, @CtgyCodeDnrm = CTGY_CODE_DNRM, @CbmtCodeDnrm = CBMT_CODE_DNRM FROM dbo.Fighter WHERE FILE_NO = @FileNo;
	
	IF @OprtType = '001' --تمدید گروهی
	BEGIN
	   IF @FromDate IS NULL RAISERROR(N'تاریخ شروع مشخص نشده', 16, 1);
	   IF @ToDate IS NULL RAISERROR(N'تاریخ پایان مشخص نشده',16, 1);
	   IF @NewCbmtCode IS NULL RAISERROR(N'زمان ساعت کلاسی جدید را وارد نکرده اید', 16, 1);
	   IF @NewMtodCode IS NULL RAISERROR(N'گروه جدید را وارد نکرده اید', 16, 1);
	   IF @NewCtgyCode IS NULL RAISERROR(N'زیرگروه جدید را وارد نکرده اید', 16, 1);
	   
	   SET @X = '<Process><Request rqtpcode="009" rqttcode="" regncode="" prvncode=""><Request_Row fileno=""><Fighter mtodcodednrm="" ctgycodednrm="" cbmtcodednrm=""/><Member_Ship strtdate="" enddate="" prntcont="1" numbmontofer="" numbofattnmont="" numbofattnweek="" attndaytype=""/></Request_Row></Request></Process>';
      SET @X.modify('replace value of (/Process/Request/@rqttcode)[1] with sql:variable("@RqttCode")');
      SET @X.modify('replace value of (/Process/Request/@regncode)[1] with sql:variable("@RegnCode")');
      SET @X.modify('replace value of (/Process/Request/@prvncode)[1] with sql:variable("@PrvnCode")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/@fileno)[1] with sql:variable("@FileNo")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/Fighter/@mtodcodednrm)[1] with sql:variable("@NewMtodCode")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/Fighter/@ctgycodednrm)[1] with sql:variable("@NewCtgyCode")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/Fighter/@cbmtcodednrm)[1] with sql:variable("@NewCbmtCode")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@strtdate)[1] with sql:variable("@FromDate")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@enddate)[1] with sql:variable("@ToDate")');      
      SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@numbmontofer)[1] with sql:variable("@NumbMontOfer")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@numbofattnmont)[1] with sql:variable("@NumbOfAttnMont")');
      EXEC UCC_TRQT_P @X;   
      
      UPDATE ms
         SET ms.NUMB_OF_ATTN_MONT = @NumbOfAttnMont
            ,ms.NUMB_MONT_OFER = @NumbMontOfer
        FROM dbo.Member_Ship ms, dbo.Fighter f
       WHERE ms.FIGH_FILE_NO = f.FILE_NO
         AND ms.RQRO_RQST_RQID = f.RQST_RQID
         AND f.FILE_NO = @Fileno;

      UPDATE f
         SET f.CTGY_CODE_DNRM = @NewCtgyCode
            ,f.MTOD_CODE_DNRM = @NewMtodCode
            ,f.CBMT_CODE_DNRM = @NewCbmtCode
        FROM dbo.Fighter f
       WHERE f.FILE_NO = @Fileno;
      
	END
	ELSE IF @OprtType = '002' -- تغییر برنامه کلاسی گروهی
	BEGIN
	   IF @NewCbmtCode IS NULL RAISERROR(N'زمان ساعت کلاسی جدید را وارد نکرده اید', 16, 1);
	      
	   SELECT @X = (
	      SELECT 0 AS '@rqid'
               ,'002' AS '@rqtpcode'
               ,'004' AS '@rqttcode'
               ,(
                  SELECT 
                     @FileNo AS '@fileno'
                  --FROM dbo.Fighter F
                  --WHERE f.FILE_NO = @FileNo
                  FOR XML PATH('Request_Row'), TYPE 
               )
            FOR XML PATH('Request'), ROOT('Process'), TYPE
	   )	 
	   EXEC dbo.PBL_RQST_F @X = @X; -- xml	        
	   
	   SELECT @X = (
	      SELECT R.RQID AS '@rqid'
               ,'002' AS '@rqtpcode'
               ,'004' AS '@rqttcode'
               ,(
                  SELECT 
                     F.File_No AS '@fileno',
                     (
                        SELECT TYPE AS 'Type'
                              ,FRST_NAME AS 'Frst_Name'
                              ,LAST_NAME AS 'Last_Name'
                              ,FATH_NAME AS 'Fath_Name'
                              ,SEX_TYPE AS 'Sex_Type'
                              ,NATL_CODE AS 'Natl_Code'
                              ,BRTH_DATE AS 'Brth_Date'
                              ,CELL_PHON AS 'Cell_Phon'
                              ,TELL_PHON AS 'Tell_Phon'
                              ,POST_ADRS AS 'Post_Adrs'
                              ,EMAL_ADRS AS 'Emal_Adrs'
                              ,INSR_NUMB AS 'Insr_Numb'
                              ,INSR_DATE AS 'Insr_Date'
                              ,EDUC_DEG AS 'Educ_Deg'
                              ,@NewCbmtCode AS 'Cbmt_Code'
                              ,DISE_CODE AS 'Dise_Code'
                              ,CALC_EXPN_TYPE AS 'Calc_Expn_Type'
                              ,COCH_DEG AS 'Coch_Deg'    
                              ,COCH_CRTF_DATE AS 'Coch_Crft_Date'
                              ,GUDG_DEG AS 'Gudg_Deg'
                              ,GLOB_CODE AS 'Glob_Code'
                              ,BLOD_GROP AS 'Blod_Grop'
                              ,FNGR_PRNT AS 'Fngr_Prnt'
                              ,SUNT_BUNT_DEPT_ORGN_CODE AS 'Sunt_Bunt_Dept_Orgn_Code'
                              ,SUNT_BUNT_DEPT_CODE AS 'Sunt_Bunt_Dept_Code'
                              ,SUNT_BUNT_CODE AS 'Sunt_Bunt_Code'
                              ,SUNT_CODE AS 'Sunt_Code'
                              ,CORD_X AS 'Cord_X'
                              ,CORD_Y AS 'Cord_Y'
                              ,MOST_DEBT_CLNG AS 'Most_Debt_Clng'
                              ,SERV_NO AS 'Serv_No'
                          FROM Fighter_Public 
                         WHERE F.FILE_NO = dbo.Fighter_Public .FIGH_FILE_NO
                           AND F.FGPB_RWNO_DNRM = dbo.Fighter_Public.RWNO
                           AND dbo.Fighter_Public.RECT_CODE = '004'
                           FOR XML PATH('Fighter_Public'), TYPE 
                     )
                  --FROM dbo.Fighter F
                  --WHERE f.FILE_NO = @FileNo
                  FOR XML PATH('Request_Row'), TYPE 
               )
               FROM Request R, dbo.Fighter F
              WHERE R.Rqid = F.RQST_RQID  
                AND F.FILE_NO = @FileNo            
            FOR XML PATH('Request'), ROOT('Process'), TYPE
	   )	 
	   EXEC dbo.PBL_RQST_F @X = @X; -- xml	        
	END
	ELSE IF @OprtType = '003'
	BEGIN
	   IF @NewCbmtCode IS NULL RAISERROR(N'زمان ساعت کلاسی جدید را وارد نکرده اید', 16, 1);
	   IF @NewMtodCode IS NULL RAISERROR(N'گروه جدید مشخص نشده', 16, 1);
	   IF @NewCtgyCode IS NULL RAISERROR(N'زیرگروه جدید مشخص نشده', 16, 1);
	      
	   SELECT @X = (
	      SELECT 0 AS '@rqid'
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
            FOR XML PATH('Request'), ROOT('Process'), TYPE
	   )	 
	   EXEC dbo.CMC_RQST_F @X = @X -- xml
	END

   SELECT @RqstRqid = F.RQST_RQID
     FROM Fighter F
    WHERE F.FILE_NO = @FileNo;
   
   UPDATE dbo.Aggregation_Operation_Detail
      SET RQST_RQID = @RqstRqid
    WHERE AGOP_CODE = @AgopCode
      AND RWNO = @Rwno
      AND FIGH_FILE_NO = @FileNo;

	
	COMMIT TRANSACTION T$AGOP_CRQT_P;
	END TRY
	BEGIN CATCH
	   DECLARE @ErrorMessage NVARCHAR(MAX);
	   SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T$AGOP_CRQT_P;
	END CATCH;	
END
GO
