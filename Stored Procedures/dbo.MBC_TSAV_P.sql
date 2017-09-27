SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[MBC_TSAV_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN   
	DECLARE @ErrorMessage NVARCHAR(MAX);
	BEGIN TRAN T1;
	BEGIN TRY
	   DECLARE @Rqid     BIGINT,
	           @FileNo   BIGINT,
	           @RqroRwno SMALLINT;
   	
	   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT');

   	SELECT @RqroRwno = RWNO
   	      ,@FileNo   = FIGH_FILE_NO
   	  FROM Request_Row
   	 WHERE RQST_RQID = @Rqid;
      
      UPDATE Payment_Detail
         SET PAY_STAT = '002'
            ,RCPT_MTOD = @x.query('//Payment_Detail[@code=sql:column("Code")]').value('(Payment_Detail/@rcptmtod)[1]', 'VARCHAR(3)')
       WHERE PYMT_RQST_RQID = @Rqid
         AND @x.query('//Payment').value('(Payment/@setondebt)[1]', 'BIT') = 0;

      DECLARE @StrtDate DATE
             ,@EndDate  DATE
             ,@PrntCont SMALLINT
             ,@NumbMontOfer INT
             ,@NumbOfAttnMont INT
             ,@NumbOfAttnWeek INT
             ,@AttnDayType VARCHAR(3);

      SELECT @StrtDate = STRT_DATE
            ,@EndDate  = END_DATE
            ,@PrntCont = PRNT_CONT
            ,@NumbMontOfer = NUMB_MONT_OFER
            ,@NumbOfAttnMont = NUMB_OF_ATTN_MONT
            ,@NumbOfAttnWeek = NUMB_OF_ATTN_WEEK
            ,@AttnDayType = ATTN_DAY_TYPE
        FROM Member_Ship
       WHERE RQRO_RQST_RQID = @Rqid
         AND RQRO_RWNO      = @RqroRwno
         AND FIGH_FILE_NO   = @FileNo;
      
      IF NOT EXISTS(SELECT * FROM Member_Ship WHERE RQRO_RQST_RQID = @Rqid AND RQRO_RWNO = @RqroRwno AND FIGH_FILE_NO = @FileNo AND RECT_CODE = '004')
         EXEC INS_MBSP_P @Rqid, @RqroRwno, @FileNo, '004', '003', @StrtDate, @EndDate, @PrntCont, @NumbMontOfer, @NumbOfAttnMont, @NumbOfAttnWeek, @AttnDayType;
      ELSE
         EXEC UPD_MBSP_P @Rqid, @RqroRwno, @FileNo, '004', '003', @StrtDate, @EndDate, @PrntCont, @NumbMontOfer, @NumbOfAttnMont, @NumbOfAttnWeek, @AttnDayType;
      
      UPDATE Request
         SET RQST_STAT = '002'
       WHERE RQID = @Rqid;

      -- 1395/06/17 * ثبت تغییرات مورد نیاز در مورد سبک و رسته و ساعت کلاسی    
      DECLARE @MtodCode BIGINT
             ,@CtgyCode BIGINT
             ,@CbmtCode BIGINT
             ,@FgpbRwnoDnrm INT
             ,@RegnCode VARCHAR(3)
             ,@PrvnCode VARCHAR(3)
             ,@ExistsNewPublic BIT = 0;
      
      SELECT @MtodCode = MTOD_CODE_DNRM
            ,@CtgyCode = CTGY_CODE_DNRM
            ,@CbmtCode = CBMT_CODE_DNRM
            ,@FgpbRwnoDnrm = FGPB_RWNO_DNRM
            ,@RegnCode = REGN_CODE
            ,@PrvnCode = REGN_PRVN_CODE
        FROM dbo.Fighter
       WHERE FILE_NO = @FileNo;
      
      -- آیا سبک و رسته تغییر کرده است 
      IF EXISTS(
         SELECT *
           FROM dbo.Fighter_Public
          WHERE FIGH_FILE_NO = @FileNo
            AND RWNO = @FgpbRwnoDnrm
            AND RECT_CODE = '004'
            AND (MTOD_CODE <> @MtodCode
               OR CTGY_CODE <> @CtgyCode )
      )
      BEGIN
         SET @X = '<Process><Request rqstrqid="" rqtpcode="011" rqttcode="004" regncode="" prvncode=""><Request_Row fileno=""><ChngMtodCtgy><Mtod_Code/><Ctgy_Code/> </ChngMtodCtgy></Request_Row></Request></Process>';
         SET @X.modify('replace value of (/Process/Request/@rqstrqid)[1] with sql:variable("@Rqid")');
         SET @X.modify('replace value of (/Process/Request/@regncode)[1] with sql:variable("@RegnCode")');
         SET @X.modify('replace value of (/Process/Request/@prvncode)[1] with sql:variable("@PrvnCode")');
         SET @X.modify('replace value of (/Process/Request/Request_Row/@fileno)[1] with sql:variable("@FileNo")');
         SET @X.modify('replace value of (/Process/Request/Request_Row/ChngMtodCtgy/@Mtod_Code)[1] with sql:variable("@MtodCode")');
         SET @X.modify('replace value of (/Process/Request/Request_Row/ChngMtodCtgy/@Ctgy_Code)[1] with sql:variable("@CtgyCode")');      
         EXEC CMC_RQST_F @X;
         
         SELECT @Rqid = R.RQID
           FROM Request R
          WHERE R.RQST_RQID = @Rqid
            AND R.RQST_STAT = '001'
            AND R.RQTP_CODE = '011'
            AND R.RQTT_CODE = '004';

         SET @X = '<Process><Request rqid="" rqtpcode="011" rqttcode="004" regncode="" prvncode=""><Request_Row fileno=""><ChngMtodCtgy><Mtod_Code/><Ctgy_Code/> </ChngMtodCtgy></Request_Row></Request></Process>';
         SET @X.modify('replace value of (/Process/Request/@rqid)[1] with sql:variable("@Rqid")');
         SET @X.modify('replace value of (/Process/Request/@regncode)[1] with sql:variable("@RegnCode")');
         SET @X.modify('replace value of (/Process/Request/@prvncode)[1] with sql:variable("@PrvnCode")');
         SET @X.modify('replace value of (/Process/Request/Request_Row/@fileno)[1] with sql:variable("@FileNo")');
         SET @X.modify('replace value of (/Process/Request/Request_Row/ChngMtodCtgy/@Mtod_Code)[1] with sql:variable("@MtodCode")');
         SET @X.modify('replace value of (/Process/Request/Request_Row/ChngMtodCtgy/@Ctgy_Code)[1] with sql:variable("@CtgyCode")');      
         EXEC CMC_SAVE_F @X;
         SET @ExistsNewPublic = 1;
      END
      
      IF @ExistsNewPublic = 1
      BEGIN         
         UPDATE dbo.Fighter_Public
            SET CBMT_CODE = @CbmtCode
          WHERE RQRO_RQST_RQID = @Rqid
            AND RECT_CODE = '004';          
      END
      ELSE IF EXISTS(
         SELECT *
           FROM dbo.Fighter_Public
          WHERE FIGH_FILE_NO = @FileNo
            AND RWNO = @FgpbRwnoDnrm
            AND RECT_CODE = '004'
            AND (CBMT_CODE <> @CbmtCode)
      )
      BEGIN
         -- اگر تغییری در سبک و رسته ایجاد نشده باشد باید تغییر مشخصات عمومی مجزایی برای ثبت ساعت کلاسی ذخیره کنیم
         SET @X = '<Process><Request rqstrqid="" rqtpcode="002" rqttcode="004" regncode="" prvncode=""><Request_Row fileno=""></Request_Row></Request></Process>';
         SET @X.modify('replace value of (/Process/Request/@rqstrqid)[1] with sql:variable("@Rqid")');
         SET @X.modify('replace value of (/Process/Request/@regncode)[1] with sql:variable("@RegnCode")');
         SET @X.modify('replace value of (/Process/Request/@prvncode)[1] with sql:variable("@PrvnCode")');
         SET @X.modify('replace value of (/Process/Request/Request_Row/@fileno)[1] with sql:variable("@FileNo")');
         --SET @CbmtCode = @CbmtCode;
         EXEC PBL_RQST_F @X;
         
         SELECT @Rqid = R.RQID
           FROM Request R
          WHERE R.RQST_RQID = @Rqid
            AND R.RQST_STAT = '001'
            AND R.RQTP_CODE = '002'
            AND R.RQTT_CODE = '004';
         
         UPDATE dbo.Fighter_Public
            SET CBMT_CODE = @CbmtCode
          WHERE RQRO_RQST_RQID = @Rqid
            AND FIGH_FILE_NO = @FileNo;
          
         SET @X = '<Process><Request rqid="" rqtpcode="002" rqttcode="004" regncode="" prvncode=""><Request_Row fileno=""></Request_Row></Request></Process>';
         SET @X.modify('replace value of (/Process/Request/@rqid)[1] with sql:variable("@Rqid")');
         SET @X.modify('replace value of (/Process/Request/@regncode)[1] with sql:variable("@RegnCode")');
         SET @X.modify('replace value of (/Process/Request/@prvncode)[1] with sql:variable("@PrvnCode")');
         SET @X.modify('replace value of (/Process/Request/Request_Row/@fileno)[1] with sql:variable("@FileNo")');
         EXEC PBL_SAVE_F @X;
      END
      
       
      COMMIT TRAN T1;
   END TRY
   BEGIN CATCH
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T1;
   END CATCH; 
END
GO
