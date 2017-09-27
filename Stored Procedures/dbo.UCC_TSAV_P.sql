SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UCC_TSAV_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	
	DECLARE @ErrorMessage NVARCHAR(MAX);
	BEGIN TRAN T1;
	BEGIN TRY
	   DECLARE @Rqid     BIGINT,
	           @OrgnRqid BIGINT,
	           @FileNo   BIGINT,
	           @RqroRwno SMALLINT;
   	
	   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT')
	         ,@OrgnRqid     = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT');

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
         EXEC INS_MBSP_P @Rqid, @RqroRwno, @FileNo, '004', '001', @StrtDate, @EndDate, @PrntCont, @NumbMontOfer, @NumbOfAttnMont, @NumbOfAttnWeek, @AttnDayType;
      ELSE
         EXEC UPD_MBSP_P @Rqid, @RqroRwno, @FileNo, '004', '001', @StrtDate, @EndDate, @PrntCont, @NumbMontOfer, @NumbOfAttnMont, @NumbOfAttnWeek, @AttnDayType;
      
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
             ,@ExistsNewPublic BIT;
      
      SELECT @MtodCode = MTOD_CODE_DNRM
            ,@CtgyCode = CTGY_CODE_DNRM
            ,@CbmtCode = CBMT_CODE_DNRM
            ,@FgpbRwnoDnrm = FGPB_RWNO_DNRM
            ,@RegnCode = REGN_CODE
            ,@PrvnCode = REGN_PRVN_CODE
        FROM dbo.Fighter
       WHERE FILE_NO = @FileNo;
      
      -- 1396/04/29 * اگر تمدید هزینه دار باشد نام مربی باید در این قسمت بروزرسانی شود
      UPDATE Payment_Detail
         SET FIGH_FILE_NO = (SELECT COCH_FILE_NO FROM dbo.Club_Method WHERE CODE = @CbmtCode)
            ,CBMT_CODE_DNRM = @CbmtCode
       WHERE PYMT_RQST_RQID = @Rqid;         
      
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
         SET @X = N'<Process><Request rqstrqid="" rqtpcode="011" rqttcode="004" regncode="" prvncode="" rqstdesc="درخواست ویرایش سبک و رسته پیرو تمدید مشترک بخاطر عوض شدن نوع سبک و رسته"><Request_Row fileno=""><ChngMtodCtgy><Mtod_Code/><Ctgy_Code/> </ChngMtodCtgy></Request_Row></Request></Process>';
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
               ,COCH_FILE_NO = (SELECT COCH_FILE_NO FROM dbo.Club_Method WHERE CODE = @CbmtCode)
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
         SET @X = N'<Process><Request rqstrqid="" rqtpcode="002" rqttcode="004" regncode="" prvncode="" rqstdesc="درخواست ویرایش برنامه کلاسی مشترک پیرو تمدید مشترک بخاطر عوض شدن برنامه و ساعت کلاسی و مربی"><Request_Row fileno=""></Request_Row></Request></Process>';
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
               ,COCH_FILE_NO = (SELECT COCH_FILE_NO FROM dbo.Club_Method WHERE CODE = @CbmtCode)
          WHERE RQRO_RQST_RQID = @Rqid
            AND FIGH_FILE_NO = @FileNo;
         
         SET @X = '<Process><Request rqid="" rqtpcode="002" rqttcode="004" regncode="" prvncode=""><Request_Row fileno=""></Request_Row></Request></Process>';
         SET @X.modify('replace value of (/Process/Request/@rqid)[1] with sql:variable("@Rqid")');
         SET @X.modify('replace value of (/Process/Request/@regncode)[1] with sql:variable("@RegnCode")');
         SET @X.modify('replace value of (/Process/Request/@prvncode)[1] with sql:variable("@PrvnCode")');
         SET @X.modify('replace value of (/Process/Request/Request_Row/@fileno)[1] with sql:variable("@FileNo")');
         EXEC PBL_SAVE_F @X;
      END
      
      -- 1395/07/26 ** اگر جلسه خصوصی با مربی در نظر گرفته شده باشد باید درخواست تمدید جلسه خصوصی هم درج گردد 
      IF EXISTS(
         SELECT *
           FROM dbo.Request R, dbo.Request_Row Rr, dbo.Payment P, dbo.Payment_Detail Pd, dbo.Expense E
          WHERE R.RQID = Rr.RQST_RQID
            AND R.RQID = P.RQST_RQID
            AND Rr.RQST_RQID = Pd.PYMT_RQST_RQID
            AND Rr.RWNO = Pd.RQRO_RWNO
            AND Pd.EXPN_CODE = E.CODE
            AND R.RQID = @OrgnRqid -- درخواست ثبت نام هنرجو
            AND E.PRVT_COCH_EXPN = '002' -- هزینه مربی خصوصی            
      )
      BEGIN
         -- ثبت درخواست جلسه خصوصی با مربی
         SET @X = N'<Process><Request rqstrqid="" rqtpcode="021" rqttcode="004" regncode="" prvncode="" rqstdesc="درخواست کلاس خصوصی اعضا پیرو تمدید اعضا بخاطر استفاده از هزینه جلسه خصوصی"><Request_Row fileno=""><Member_Ship strtdate="" enddate="" prntcont="1" numbmontofer="" numbofattnmont="" numbofattnweek="" attndaytype=""/></Request_Row></Request></Process>';
         SET @X.modify('replace value of (/Process/Request/@rqstrqid)[1] with sql:variable("@Rqid")');
         SET @X.modify('replace value of (/Process/Request/@regncode)[1] with sql:variable("@RegnCode")');
         SET @X.modify('replace value of (/Process/Request/@prvncode)[1] with sql:variable("@PrvnCode")');
         SET @X.modify('replace value of (/Process/Request/Request_Row/@fileno)[1] with sql:variable("@FileNo")');
         SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@strtdate)[1] with sql:variable("@StrtDate")');
         SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@enddate)[1] with sql:variable("@EndDate")');      
         SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@numbmontofer)[1] with sql:variable("@NumbMontOfer")');
         SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@numbofattnmont)[1] with sql:variable("@NumbOfAttnMont")');
         SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@numbofattnweek)[1] with sql:variable("@NumbOfAttnWeek")');
         SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@attndaytype)[1] with sql:variable("@AttnDayType")');
         EXEC MBC_TRQT_P @X;
         
         SELECT @Rqid = R.RQID
           FROM Request R
          WHERE R.RQST_RQID = @Rqid
            AND R.RQST_STAT = '001'
            AND R.RQTP_CODE = '021'
            AND R.RQTT_CODE = '004';

         SET @X = '<Process><Request rqid=""></Request></Process>';
         SET @X.modify('replace value of (/Process/Request/@rqid)[1] with sql:variable("@Rqid")');
         EXEC MBC_TSAV_P @X;
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
