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
	--RETURN;
	DECLARE @ErrorMessage NVARCHAR(MAX);
	BEGIN TRAN T1;
	BEGIN TRY
	   DECLARE @Rqid     BIGINT,
	           @OrgnRqid BIGINT,
	           @FileNo   BIGINT,
	           @RqroRwno SMALLINT,
	           @FgpbRwno INT;
   	
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
             ,@AttnDayType VARCHAR(3)
             ,@NewFngrPrnt VARCHAR(20);

      SELECT @StrtDate = STRT_DATE
            ,@EndDate  = END_DATE
            ,@PrntCont = PRNT_CONT
            ,@NumbMontOfer = NUMB_MONT_OFER
            ,@NumbOfAttnMont = NUMB_OF_ATTN_MONT
            ,@NumbOfAttnWeek = NUMB_OF_ATTN_WEEK
            ,@AttnDayType = ATTN_DAY_TYPE
            ,@NewFngrPrnt = NEW_FNGR_PRNT
        FROM Member_Ship
       WHERE RQRO_RQST_RQID = @Rqid
         AND RQRO_RWNO      = @RqroRwno
         AND FIGH_FILE_NO   = @FileNo;
      
      -- 1398/04/06 * اگر کد شناسایی خالی باشد
      IF @NewFngrPrnt = '' SET @NewFngrPrnt = NULL;
      
      IF NOT EXISTS(SELECT * FROM Member_Ship WHERE RQRO_RQST_RQID = @Rqid AND RQRO_RWNO = @RqroRwno AND FIGH_FILE_NO = @FileNo AND RECT_CODE = '004')
         EXEC INS_MBSP_P @Rqid, @RqroRwno, @FileNo, '004', '001', @StrtDate, @EndDate, @PrntCont, @NumbMontOfer, @NumbOfAttnMont, @NumbOfAttnWeek, @AttnDayType;
      ELSE
         EXEC UPD_MBSP_P @Rqid, @RqroRwno, @FileNo, '004', '001', @StrtDate, @EndDate, @PrntCont, @NumbMontOfer, @NumbOfAttnMont, @NumbOfAttnWeek, @AttnDayType;
      
      -- 1398/04/05 * بدلیل اضافه شدن گزینه جدید برای عوض کردن کد شناسایی مشتری
      UPDATE dbo.Member_Ship 
         SET NEW_FNGR_PRNT = @NewFngrPrnt 
       WHERE RQRO_RQST_RQID = @Rqid
         AND RQRO_RWNO = @RqroRwno
         AND RECT_CODE = '004';      


      -- 1396/08/18 * اگر درون تخفیفات مشترک گزینه ای باشد که مبلغ تخفیف مابه التفاوت وجود داشته باشد بایستی 
      -- مبلغ بدهی قبلی را به عنوان تخفیف مابه التفاوت لحاظ شود و تسویه حساب کامل انجام شود         
      --IF EXISTS(
      --   SELECT *
      --     FROM dbo.Payment_Discount
      --    WHERE AMNT_TYPE = '004'   
      --      AND PYMT_RQST_RQID = @Rqid       
      --)
      --BEGIN
      --   -- 1396/08/18 * بدست آوردن درخواست ثبت نام قبلی
      --   DECLARE @OldRqid BIGINT
      --   SELECT TOP 1 @OldRqid = RQID
      --     FROM dbo.[VF$Request_Changing](@FileNo)
      --    WHERE RQTT_CODE != '004'
      --      AND RQTP_CODE IN ('001' , '009')
      -- ORDER BY SAVE_DATE DESC;
      --   -- اگر مشترک نسبت به دوره قبلی بدهکار باشد
      --   IF EXISTS(
      --      SELECT *
      --        FROM dbo.Payment
      --       WHERE RQST_RQID = @OldRqid
      --         AND (SUM_EXPN_PRIC + SUM_EXPN_EXTR_PRCT) - (SUM_RCPT_EXPN_PRIC + ISNULL(SUM_PYMT_DSCN_DNRM, 0)) > 0
      --   )
      --   BEGIN
      --      INSERT INTO dbo.Payment_Discount ( PYMT_CASH_CODE ,PYMT_RQST_RQID ,RQRO_RWNO ,RWNO ,AMNT ,AMNT_TYPE ,STAT ,PYDS_DESC )
      --      SELECT CASH_CODE, RQST_RQID, 1, 0, (SUM_EXPN_PRIC + SUM_EXPN_EXTR_PRCT) - (SUM_RCPT_EXPN_PRIC + ISNULL(SUM_PYMT_DSCN_DNRM, 0)), '004', '002', N'کسر مبلغ مابه التفاوت بدهی شهریه بابت جابه جایی کلاس'
      --        FROM dbo.Payment
      --       WHERE RQST_RQID = @OldRqid
      --         AND (SUM_EXPN_PRIC + SUM_EXPN_EXTR_PRCT) - (SUM_RCPT_EXPN_PRIC + ISNULL(SUM_PYMT_DSCN_DNRM, 0)) > 0;
            
      --      UPDATE dbo.Payment_Detail
      --         SET PAY_STAT = '002'
      --       WHERE PYMT_RQST_RQID = @OldRqid;
      --   END
      --END

      
      UPDATE Request
         SET RQST_STAT = '002'
       WHERE RQID = @Rqid;
      
      -- 1395/06/17 * ثبت تغییرات مورد نیاز در مورد سبک و رسته و ساعت کلاسی    
      DECLARE @MtodCode BIGINT
             ,@CtgyCode BIGINT
             ,@CbmtCode BIGINT
             ,@FgpbRwnoDnrm INT
             ,@GlobCode NVARCHAR(50)
             ,@RegnCode VARCHAR(3)
             ,@PrvnCode VARCHAR(3)
             ,@ExistsNewPublic BIT;
      
      SELECT @MtodCode = MTOD_CODE_DNRM
            ,@CtgyCode = CTGY_CODE_DNRM
            ,@CbmtCode = CBMT_CODE_DNRM
            ,@FgpbRwnoDnrm = FGPB_RWNO_DNRM
            ,@GlobCode = GLOB_CODE_DNRM
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
            AND (ISNULL(MTOD_CODE, 0) <> @MtodCode
               OR ISNULL(CTGY_CODE, 0) <> @CtgyCode 
               OR FNGR_PRNT <> ISNULL(@NewFngrPrnt, FNGR_PRNT))
      )
      BEGIN
         SET @X = N'<Process><Request rqstrqid="" rqtpcode="011" rqttcode="004" regncode="" prvncode="" rqstdesc="درخواست ویرایش اطلاعات عمومی پیرو تمدید مشترک بخاطر عوض شدن نوع گروه و زیر گروه یا کد شناسایی جدید"><Request_Row fileno=""><ChngMtodCtgy><Mtod_Code/><Ctgy_Code/> </ChngMtodCtgy></Request_Row></Request></Process>';
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
               ,TYPE = CASE [TYPE] WHEN '009' THEN '001' ELSE [TYPE] END
               ,FNGR_PRNT = CASE WHEN ISNULL(@NewFngrPrnt, '') != '' THEN @NewFngrPrnt ELSE FNGR_PRNT END
          WHERE RQRO_RQST_RQID = @Rqid
            AND RECT_CODE = '004';
         
         -- 1396/10/13 * بدست آوردن ردیف عمومی در جدول تمدید
         SELECT @FgpbRwno = RWNO
           FROM dbo.Fighter_Public
          WHERE RQRO_RQST_RQID = @Rqid
            AND RECT_CODE = '004';
      END
      
      ELSE IF EXISTS(
         SELECT *
           FROM dbo.Fighter_Public
          WHERE FIGH_FILE_NO = @FileNo
            AND RWNO = @FgpbRwnoDnrm
            AND RECT_CODE = '004'
            AND (ISNULL(CBMT_CODE, 0) <> @CbmtCode)
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
               ,TYPE = CASE [TYPE] WHEN '009' THEN '001' ELSE [TYPE] END
               ,FNGR_PRNT = CASE WHEN ISNULL(@NewFngrPrnt, '') != '' THEN @NewFngrPrnt ELSE FNGR_PRNT END
          WHERE RQRO_RQST_RQID = @Rqid
            AND FIGH_FILE_NO = @FileNo;
         
         SET @X = '<Process><Request rqid="" rqtpcode="002" rqttcode="004" regncode="" prvncode=""><Request_Row fileno=""></Request_Row></Request></Process>';
         SET @X.modify('replace value of (/Process/Request/@rqid)[1] with sql:variable("@Rqid")');
         SET @X.modify('replace value of (/Process/Request/@regncode)[1] with sql:variable("@RegnCode")');
         SET @X.modify('replace value of (/Process/Request/@prvncode)[1] with sql:variable("@PrvnCode")');
         SET @X.modify('replace value of (/Process/Request/Request_Row/@fileno)[1] with sql:variable("@FileNo")');
         EXEC PBL_SAVE_F @X;
         
         -- 1396/10/13 * بدست آوردن ردیف عمومی
         SELECT @FgpbRwno = RWNO
           FROM dbo.Fighter_Public
          WHERE RQRO_RQST_RQID = @Rqid
            AND RECT_CODE = '004';           
      END
      
      IF @FgpbRwno IS NULL OR @FgpbRwno = 0
         SELECT @FgpbRwno = FGPB_RWNO_DNRM
           FROM dbo.Fighter
          WHERE FILE_NO = @FileNo;
      
      -- 1396/11/18 * اضافه شدن تاریخ تعطیلی ها در سیستم
      DECLARE @HldyNumb INT;
      SELECT @HldyNumb = COUNT(h.CODE)
        FROM dbo.Holidays h, dbo.Member_Ship ms
       WHERE ms.RQRO_RQST_RQID = @Rqid
         AND ms.RECT_CODE = '004'
         AND ms.VALD_TYPE = '002'
         AND h.HLDY_DATE BETWEEN CAST(ms.STRT_DATE AS DATE) AND CAST(ms.END_DATE AS DATE);
      
      -- 1397/01/14 * ضریب اضافه شدن تعداد روز به ازای تعطیلی ها
      SELECT TOP 1 @HldyNumb = @HldyNumb * ISNULL(HLDY_CONT, 1)
        FROM dbo.Settings;
      
      -- 1396/11/23 * بررسی اینکه تعداد جلسات برای مشترکین اشتراکی که تعداد جلسات در تعداد خانوار ضرب شود
      DECLARE @SharGlobCont INT = 1;
      IF EXISTS(SELECT * FROM dbo.Club_Method cm, dbo.Settings s WHERE cm.CLUB_CODE = s.CLUB_CODE AND cm.CODE = @CbmtCode AND s.SHAR_MBSP_STAT = '002') AND @GlobCode IS NOT NULL AND @GlobCode != '' AND LEN(@GlobCode) > 2 AND EXISTS(SELECT * FROM dbo.Method WHERE CODE = @MtodCode AND CHCK_ATTN_ALRM = '002')
      BEGIN         
         SELECT @SharGlobCont = COUNT(*)
           FROM dbo.Fighter
          WHERE CONF_STAT = '002'
            AND ACTV_TAG_DNRM >= '101'
            AND GLOB_CODE_DNRM = @GlobCode;
      END

      -- 1397/04/28 * بدست آوردن تعداد جلسات مصرف شده دیگر مشارکین
      DECLARE @OthrFileNo BIGINT,
              @SumAttnMont INT = 0;
      IF @SharGlobCont > 1
      BEGIN
		SELECT TOP 1 @OthrFileNo = f.FILE_NO
		  FROM dbo.Fighter f
		 WHERE f.FILE_NO != @FileNo
		   AND f.GLOB_CODE_DNRM = @GlobCode
		   AND f.CONF_STAT = '002'
		   AND f.ACTV_TAG_DNRM >= '101';
        
        SELECT @SumAttnMont = ms.SUM_ATTN_MONT_DNRM
          FROM dbo.Member_Ship ms, dbo.Fighter_Public fp, dbo.Method m
         WHERE ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
           AND ms.FGPB_RWNO_DNRM = fp.RWNO
           AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
           AND ms.FIGH_FILE_NO = @OthrFileNo
           AND ms.RECT_CODE = '004'
           AND fp.MTOD_CODE = m.CODE
           AND m.CHCK_ATTN_ALRM = '002' -- ورزش مشارکتی میباشد
           AND fp.MTOD_CODE = @MtodCode
           AND ISNULL(ms.NUMB_OF_ATTN_MONT, 0) > 0
		     --AND ISNULL(Ms.NUMB_OF_ATTN_MONT, 0) >= ISNULL(Ms.SUM_ATTN_MONT_DNRM, 0) 
           AND CAST(GETDATE() AS DATE) BETWEEN CAST(ms.STRT_DATE AS DATE) AND CAST(ms.END_DATE AS DATE)
           AND ms.VALD_TYPE = '002';
      END
      
      -- 1396/10/13 * ثبت گزینه ردیف عمومی در جدول تمدید
      UPDATE dbo.Member_Ship
         SET FGPB_RWNO_DNRM = @FgpbRwno
            ,FGPB_RECT_CODE_DNRM = '004'
            ,END_DATE = DATEADD(DAY, @HldyNumb, END_DATE)
            ,NUMB_OF_ATTN_MONT = NUMB_OF_ATTN_MONT * @SharGlobCont
            ,SUM_ATTN_MONT_DNRM = @SumAttnMont -- در این قسمت باید بررسی شود که نفرهای قبلی آیا از گزینه استخر استفاده کرده اند یا خیر
       WHERE RQRO_RQST_RQID = @OrgnRqid;

      -- 1397/04/28 * پیدا کردن آن دسته از مشتریانی که به صورت مشارکتی درون سازمان از ورزش خاصی استفاده میکنند
      IF @SharGlobCont > 1
		UPDATE ms
		   SET ms.NUMB_OF_ATTN_MONT = @NumbOfAttnMont * @SharGlobCont
		  FROM dbo.Member_Ship ms, dbo.Fighter_Public fp, dbo.Method m
		 WHERE ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
		   AND ms.FGPB_RWNO_DNRM = fp.RWNO
		   AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
		   AND ms.RECT_CODE = '004'
		   AND ms.VALD_TYPE = '002'
		   AND ms.FIGH_FILE_NO != @FileNo
		   AND fp.MTOD_CODE = m.CODE
		   AND m.CHCK_ATTN_ALRM = '002' -- ورزش مشارکتی می باشد
		   AND fp.GLOB_CODE = @GlobCode
		   AND fp.MTOD_CODE = @MtodCode
         AND ISNULL(ms.NUMB_OF_ATTN_MONT, 0) > 0
		   --AND ISNULL(Ms.NUMB_OF_ATTN_MONT, 0) >= ISNULL(Ms.SUM_ATTN_MONT_DNRM, 0) 
         AND CAST(GETDATE() AS DATE) BETWEEN CAST(ms.STRT_DATE AS DATE) AND CAST(ms.END_DATE AS DATE);
      
      -- 1395/07/26 ** اگر جلسه خصوصی با مربی در نظر گرفته شده باشد باید درخواست تمدید جلسه خصوصی هم درج گردد 
      --IF EXISTS(
      --   SELECT *
      --     FROM dbo.Request R, dbo.Request_Row Rr, dbo.Payment P, dbo.Payment_Detail Pd, dbo.Expense E
      --    WHERE R.RQID = Rr.RQST_RQID
      --      AND R.RQID = P.RQST_RQID
      --      AND Rr.RQST_RQID = Pd.PYMT_RQST_RQID
      --      AND Rr.RWNO = Pd.RQRO_RWNO
      --      AND Pd.EXPN_CODE = E.CODE
      --      AND R.RQID = @OrgnRqid -- درخواست ثبت نام هنرجو
      --      AND E.PRVT_COCH_EXPN = '002' -- هزینه مربی خصوصی            
      --)
      --BEGIN
      --   -- ثبت درخواست جلسه خصوصی با مربی
      --   SET @X = N'<Process><Request rqstrqid="" rqtpcode="021" rqttcode="004" regncode="" prvncode="" rqstdesc="درخواست کلاس خصوصی اعضا پیرو تمدید اعضا بخاطر استفاده از هزینه جلسه خصوصی"><Request_Row fileno=""><Member_Ship strtdate="" enddate="" prntcont="1" numbmontofer="" numbofattnmont="" numbofattnweek="" attndaytype=""/></Request_Row></Request></Process>';
      --   SET @X.modify('replace value of (/Process/Request/@rqstrqid)[1] with sql:variable("@Rqid")');
      --   SET @X.modify('replace value of (/Process/Request/@regncode)[1] with sql:variable("@RegnCode")');
      --   SET @X.modify('replace value of (/Process/Request/@prvncode)[1] with sql:variable("@PrvnCode")');
      --   SET @X.modify('replace value of (/Process/Request/Request_Row/@fileno)[1] with sql:variable("@FileNo")');
      --   SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@strtdate)[1] with sql:variable("@StrtDate")');
      --   SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@enddate)[1] with sql:variable("@EndDate")');      
      --   SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@numbmontofer)[1] with sql:variable("@NumbMontOfer")');
      --   SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@numbofattnmont)[1] with sql:variable("@NumbOfAttnMont")');
      --   SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@numbofattnweek)[1] with sql:variable("@NumbOfAttnWeek")');
      --   SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@attndaytype)[1] with sql:variable("@AttnDayType")');
      --   EXEC MBC_TRQT_P @X;
         
      --   SELECT @Rqid = R.RQID
      --     FROM Request R
      --    WHERE R.RQST_RQID = @Rqid
      --      AND R.RQST_STAT = '001'
      --      AND R.RQTP_CODE = '021'
      --      AND R.RQTT_CODE = '004';

      --   SET @X = '<Process><Request rqid=""></Request></Process>';
      --   SET @X.modify('replace value of (/Process/Request/@rqid)[1] with sql:variable("@Rqid")');
      --   EXEC MBC_TSAV_P @X;
      --END 
      
      DECLARE @CellPhon VARCHAR(11)
             ,@MomCellPhon VARCHAR(11)
             ,@DadCellPhon VARCHAR(11)
             ,@ChatId BIGINT
             ,@SexType VARCHAR(3)
             ,@FrstName NVARCHAR(250)
             ,@LastName NVARCHAR(250);
      
      SELECT @CellPhon = f.CELL_PHON_DNRM
            ,@MomCellPhon = f.MOM_CELL_PHON_DNRM
            ,@DadCellPhon = f.DAD_CELL_PHON_DNRM
            ,@ChatId = f.CHAT_ID_DNRM
            ,@SexType = f.SEX_TYPE_DNRM
            ,@FrstName = fp.FRST_NAME
            ,@LastName = fp.LAST_NAME
        FROM dbo.Fighter f, dbo.Fighter_Public fp
       WHERE f.FILE_NO = @FileNo
         AND f.FILE_NO = fp.FIGH_FILE_NO
         AND f.FGPB_RWNO_DNRM = fp.RWNO
         AND fp.RECT_CODE = '004';
         
      -- 1396/10/05 * ثبت پیامک 
      IF @CellPhon IS NOT NULL AND LEN(@CellPhon) != 0 AND EXISTS(SELECT * FROM dbo.Request WHERE RQID = @OrgnRqid AND RQTT_CODE = '001')
      BEGIN
         DECLARE @MsgbStat VARCHAR(3)
                ,@MsgbText NVARCHAR(MAX)
                ,@ClubName NVARCHAR(250)
                ,@InsrCnamStat VARCHAR(3)
                ,@InsrFnamStat VARCHAR(3)
                ,@LineType VARCHAR(3)
                ,@SendInfo VARCHAR(3)
                ,@MesgInfo NVARCHAR(Max)
                ,@MinNumbDayRmnd INT
                ,@AmntType VARCHAR(3)
                ,@AmntTypeDesc NVARCHAR(255);
                
         SELECT @MsgbStat = STAT
               ,@MsgbText = MSGB_TEXT
               ,@ClubName = CLUB_NAME
               ,@InsrCnamStat = INSR_CNAM_STAT
               ,@InsrFnamStat = INSR_FNAM_STAT
               ,@LineType = LINE_TYPE
               ,@SendInfo = SEND_INFO
           FROM dbo.Message_Broadcast
          WHERE MSGB_TYPE = '007';
         
  	      SELECT @AmntType = rg.AMNT_TYPE, 
	             @AmntTypeDesc = d.DOMN_DESC
	        FROM iScsc.dbo.Regulation rg, iScsc.dbo.[D$ATYP] d
	       WHERE rg.TYPE = '001'
	         AND rg.REGL_STAT = '002'
	         AND rg.AMNT_TYPE = d.VALU;
         
         -- حذف کردن پیامکی که برای چند روز دیگر میخواد بابت تمدید همین ورزش ارسال شود
         -- این گزینه بابت این مسئله اضافه میکنیم که اگر کسی جلو جلو تمدید کند دیگر به آن پیامک
         -- که جلو جلو در لیست قرار داده ایم حذف شود و ارسال نشود ولی نکته اگر مشتری چند رشته را
         -- همزمان باهم دارد استفاده میکند باید مشخص کنیم که تمدیدی که انجام داده ایا برای
         -- همین ورزشی که پیامک هشدار تمدید ارسال شده انجام داده یا خیر
         DELETE iProject.Msgb.Sms_Message_Box
          WHERE PHON_NUMB IN (@CellPhon, @MomCellPhon, @DadCellPhon)
            AND MSGB_TYPE = '009'
            AND MESG_ID IS NULL
            AND CAST(ACTN_DATE AS DATE) >= CAST(GETDATE() AS DATE)
            AND EXISTS(
                SELECT *
                  FROM dbo.Fighter f
                 WHERE f.FILE_NO = @FileNo
                   AND f.MTOD_CODE_DNRM = (
                     SELECT fp.MTOD_CODE
                       FROM dbo.Member_Ship ms, dbo.Fighter_Public fp
                      WHERE f.FILE_NO = ms.FIGH_FILE_NO
                        AND ms.RECT_CODE = '004'
                        AND ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
                        AND ms.FGPB_RWNO_DNRM = fp.RWNO
                        AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
                        AND ms.RWNO = (SELECT CASE RQTP_CODE WHEN '001' THEN 1 ELSE (SELECT RWNO FROM dbo.Member_Ship WHERE RQRO_RQST_RQID = RFID AND RECT_CODE = '004') END FROM dbo.Request WHERE RQID = RFID)
                   )
            );
         
         IF @MsgbStat = '002' 
         BEGIN
            IF @InsrFnamStat = '002'
               SET @MsgbText = (SELECT DOMN_DESC FROM dbo.[D$SXDC] WHERE VALU = @SexType) + N' ' + @FrstName + N' ' + @LastName + N' ' + @MsgbText;
            
            IF @SendInfo = '002'
            BEGIN            
               SELECT @MesgInfo =                       
                      N'اطلاعات ثبت نامی شما به شرح زیر میباشد' + CHAR(10) + 
                      m.MTOD_DESC + N' , ' + cb.CTGY_DESC + N' با سرپرستی ' + c.FRST_NAME_DNRM + N' ' + c.LAST_NAME_DNRM + CHAR(10) + 
                      N'تاریخ ثبت نام ' + dbo.GET_MTOS_U(r.SAVE_DATE) + CHAR(10) + 
                      N'شروع دوره ' + dbo.GET_MTOS_U(ms.STRT_DATE) + CHAR(10) +
                      N'پایان دوره ' + dbo.GET_MTOS_U(ms.END_DATE) + CHAR(10) + 
                      CASE ms.NUMB_OF_ATTN_MONT WHEN 0 THEN N' ' ELSE N'تعداد جلسات ' + CAST(ms.NUMB_OF_ATTN_MONT AS NVARCHAR(3)) + CHAR(10) END +
                      N'صورتحساب ' + CHAR(10) + 
                      N'مبلغ کل دوره ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, p.SUM_EXPN_PRIC + p.SUM_EXPN_EXTR_PRCT), 1), '.00', '') + N' ' + @AmntTypeDesc + CHAR(10) +
                      N'مبلغ تخفیف ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, p.SUM_PYMT_DSCN_DNRM), 1), '.00', '') + N' ' + @AmntTypeDesc + CHAR(10) +
                      N'مبلغ پرداختی ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, p.SUM_RCPT_EXPN_PRIC), 1), '.00', '') + N' ' + @AmntTypeDesc + CHAR(10) +
                      N'مبلغ بدهی دوره ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, (p.SUM_EXPN_PRIC + p.SUM_EXPN_EXTR_PRCT) - (p.SUM_PYMT_DSCN_DNRM + p.SUM_RCPT_EXPN_PRIC)), 1), '.00', '') + N' ' + @AmntTypeDesc + CHAR(10)                       
                 FROM dbo.Request r,
                      dbo.Request_Row rr,
                      dbo.Member_Ship ms, 
                      dbo.Fighter_Public fp,
                      dbo.Method m,
                      dbo.Category_Belt cb,
                      dbo.Fighter c,                      
                      dbo.Payment p
                WHERE r.RQID = rr.RQST_RQID
                  AND rr.FIGH_FILE_NO = ms.FIGH_FILE_NO
                  AND ms.RECT_CODE = '004'
                  AND ms.FGPB_RWNO_DNRM = fp.RWNO
                  AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
                  AND fp.MTOD_CODE = m.CODE
                  AND fp.CTGY_CODE = cb.CODE
                  AND m.CODE = cb.MTOD_CODE
                  AND fp.COCH_FILE_NO = c.FILE_NO
                  and rr.RQST_RQID = ms.RQRO_RQST_RQID
                  AND rr.RWNO = ms.RQRO_RWNO
                  AND r.RQID = p.RQST_RQID
                  AND r.RQID = @OrgnRqid;                  
               SET @MsgbText = @MsgbText + CHAR(10) + @MesgInfo;
            END;            
            
            IF @InsrCnamStat = '002'
               SET @MsgbText = @MsgbText + N' ' + @ClubName;
               
            DECLARE @XMsg XML;
            SELECT @XMsg = (
               SELECT 5 AS '@subsys',
                      @LineType AS '@linetype',
                      (
                        SELECT @CellPhon AS '@phonnumb',
                               (
                                   SELECT '007' AS '@type' 
                                          ,@OrgnRqid AS '@rfid'
                                          ,@MsgbText
                                      FOR XML PATH('Message'), TYPE 
                               ) 
                           FOR XML PATH('Contact'), TYPE
                      ),
                      (
                        SELECT @MomCellPhon AS '@phonnumb',
                               (
                                   SELECT '007' AS '@type' 
                                          ,@OrgnRqid AS '@rfid'
                                          ,N'مادر ' + CASE @SexType WHEN '001' THEN (N' آقا ' + @FrstName) ELSE (@FrstName + N' خانم ') END + CHAR(10) + N' اطلاعات فرزند دلبند شما با موفقیت در سامانه تمدید گردید. ' + CHAR(10) + N'با آرزوی بهترین ها برای شما خانواده ' + @LastName + N' عزیز ' + CHAR(10) + CASE @SendInfo WHEN '002' THEN @MesgInfo ELSE N' ' END + CASE @InsrCnamStat WHEN '002' THEN @ClubName ELSE N'' END 
                                      FOR XML PATH('Message'), TYPE 
                               ) 
                           FOR XML PATH('Contact'), TYPE
                      ),
                      (
                        SELECT @DadCellPhon AS '@phonnumb',
                               (
                                   SELECT '007' AS '@type' 
                                          ,@OrgnRqid AS '@rfid'
                                          ,N'پدر ' + CASE @SexType WHEN '001' THEN (N' آقا ' + @FrstName) ELSE (@FrstName + N' خانم ') END + CHAR(10) + N' اطلاعات فرزند دلبند شما با موفقیت در سامانه تمدید گردید. ' + CHAR(10) + N'با آرزوی بهترین ها برای شما خانواده ' + @LastName + N' عزیز ' + CHAR(10) + CASE @SendInfo WHEN '002' THEN @MesgInfo ELSE N' ' END + CASE @InsrCnamStat WHEN '002' THEN @ClubName ELSE N'' END 
                                      FOR XML PATH('Message'), TYPE 
                               ) 
                           FOR XML PATH('Contact'), TYPE
                      )                      
                 FOR XML PATH('Contacts'), ROOT('Process')                            
            );
            EXEC dbo.MSG_SEND_P @X = @XMsg -- xml
         END;
         
         -- ارسال پیامک هشدار جهت تمدید مجدد
            -- بررسی اینکه پیامک هشدار فعال میباشد یا خیر
            IF EXISTS(SELECT * FROM dbo.Message_Broadcast WHERE MSGB_TYPE = '009' AND STAT = '002' AND MIN_NUMB_DAY_RMND != 0)
            BEGIN
               SELECT @MsgbStat = STAT
                     ,@MsgbText = MSGB_TEXT
                     ,@ClubName = CLUB_NAME
                     ,@InsrCnamStat = INSR_CNAM_STAT
                     ,@InsrFnamStat = INSR_FNAM_STAT
                     ,@MinNumbDayRmnd = MIN_NUMB_DAY_RMND
                 FROM dbo.Message_Broadcast
                WHERE MSGB_TYPE = '009';
               
               IF @MsgbStat = '002' 
               BEGIN
                  IF @InsrFnamStat = '002'
                     SET @MsgbText = (SELECT DOMN_DESC FROM dbo.[D$SXDC] WHERE VALU = @SexType) + N' ' + @FrstName + N' ' + @LastName + N' ' + @MsgbText;
                  
                  IF @InsrCnamStat = '002'
                     SET @MsgbText = @MsgbText + N' ' + @ClubName;
                     
                  --DECLARE @XMsg XML;
                  SELECT @XMsg = (
                     SELECT 5 AS '@subsys',
                            '001' AS '@linetype',
                            (
                              SELECT @CellPhon AS '@phonnumb',
                                     (
                                         SELECT '009' AS '@type' 
                                                ,@OrgnRqid AS '@rfid'
                                                ,DATEADD(DAY, @MinNumbDayRmnd * -1, @EndDate ) AS '@actndate'
                                                ,@MsgbText
                                            FOR XML PATH('Message'), TYPE 
                                     ) 
                                 FOR XML PATH('Contact'), TYPE
                            ),
                            (
                              SELECT @DadCellPhon AS '@phonnumb',
                                     (
                                       SELECT '009' AS '@type' 
                                              ,@OrgnRqid AS '@rfid'
                                              ,DATEADD(DAY, @MinNumbDayRmnd * -1, @EndDate ) AS '@actndate'
                                              ,N'پدر ' + CASE @SexType WHEN '001' THEN (N' آقا ' + @FrstName) ELSE (@FrstName + N' خانم ') END + CHAR(10) + N' دوره فرزند شما روبه اتمام می باشد لطفا جهت تمدید دوره اقدام فرمایید ' + CHAR(10) + N'با آرزوی بهترین ها برای شما خانواده ' + @LastName + N' عزیز ' + CHAR(10) + N' تاریخ اتمام دوره ' + dbo.GET_MTOS_U(@EndDate) + CHAR(10) + CASE @InsrCnamStat WHEN '002' THEN @ClubName ELSE N'' END 
                                          FOR XML PATH('Message'), TYPE 
                                     ) 
                                 FOR XML PATH('Contact'), TYPE
                            ),
                            (
                              SELECT @MomCellPhon AS '@phonnumb',
                                     (
                                         SELECT '009' AS '@type' 
                                                ,@OrgnRqid AS '@rfid'
                                                ,DATEADD(DAY, @MinNumbDayRmnd * -1, @EndDate ) AS '@actndate'
                                                ,N'مادر ' + CASE @SexType WHEN '001' THEN (N' آقا ' + @FrstName) ELSE (@FrstName + N' خانم ') END + CHAR(10) + N' دوره فرزند شما روبه اتمام می باشد لطفا جهت تمدید دوره اقدام فرمایید ' + CHAR(10) + N'با آرزوی بهترین ها برای شما خانواده ' + @LastName + N' عزیز ' + CHAR(10) + N' تاریخ اتمام دوره ' + dbo.GET_MTOS_U(@EndDate) + CHAR(10) + CASE @InsrCnamStat WHEN '002' THEN @ClubName ELSE N'' END 
                                            FOR XML PATH('Message'), TYPE 
                                     ) 
                                 FOR XML PATH('Contact'), TYPE
                            )
                       FOR XML PATH('Contacts'), ROOT('Process')                            
                  );
                  EXEC dbo.MSG_SEND_P @X = @XMsg -- xml
               END;
            END
      END;      
      -- 1396/11/15 * ثبت پیامک تلگرام
      IF @ChatId IS NOT NULL
      BEGIN  
         DECLARE @TelgStat VARCHAR(3);
         
         SELECT @TelgStat = TELG_STAT
               --,@MsgbText = MSGB_TEXT
               ,@ClubName = CLUB_NAME
               ,@InsrCnamStat = INSR_CNAM_STAT
               ,@InsrFnamStat = INSR_FNAM_STAT
           FROM dbo.Message_Broadcast
          WHERE MSGB_TYPE = '007';
         
         -- 1396/11/29 * اضافه کردن مبلغ هزینه دوره ثبت تمدیدی 
         DECLARE @ExpnAmnt BIGINT
                ,@DscnPymt BIGINT
                ,@PymtAmnt BIGINT;
         
         SELECT @ExpnAmnt = ISNULL(SUM( EXPN_PRIC + ISNULL(EXPN_EXTR_PRCT, 0) ), 0)
           FROM dbo.Payment_Detail
          WHERE PYMT_RQST_RQID = @OrgnRqid;
         
         SELECT @DscnPymt = ISNULL(SUM(AMNT), 0)
           FROM dbo.Payment_Discount
          WHERE PYMT_RQST_RQID = @OrgnRqid;             
         
         SELECT @PymtAmnt = ISNULL(SUM(AMNT), 0)
           FROM dbo.Payment_Method
          WHERE PYMT_RQST_RQID = @OrgnRqid;
         
         IF @TelgStat = '002'
         BEGIN
            IF @InsrFnamStat = '002'
               SET @MsgbText = (SELECT DOMN_DESC FROM dbo.[D$SXDC] WHERE VALU = @SexType) + N' ' + @FrstName + N' ' + @LastName + N' ';--+ ISNULL(@MsgbText, N'');

            SELECT @MsgbText += (            
               SELECT CHAR(10) + N' شما در رشته ' + m.MTOD_DESC + N' با مربی ' + c.NAME_DNRM + N' برای ایام ' + d.DOMN_DESC + N' از ' + CAST(cm.STRT_TIME AS VARCHAR(5)) + N' تا ' + CAST(cm.END_TIME AS VARCHAR(5)) + N' ثبت نام کرده اید.' + 
                      CHAR(10) + N' مبلغ دوره شما ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, @ExpnAmnt), 1), '.00', '') + N' مبلغ پرداختی ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, @PymtAmnt), 1), '.00', '') + N' مبلغ تخفیف ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, @DscnPymt), 1), '.00', '') +
                      CASE WHEN (@ExpnAmnt - (@PymtAmnt - @DscnPymt)) > 0 THEN CHAR(10) + N' میزان بدهی شما برای دوره ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, @ExpnAmnt - (@PymtAmnt - @DscnPymt)), 1), '.00', '') ELSE N' از پرداخت شما متشکریم ' END + 
                      CHAR(10) + N' از اینکه دوره جدید ورزشی خود را با ما انجام میدهید بسیار خرسندیم. با آرزوی موفقیت و سلامتی برای شما' + 
                      CHAR(10)                      
                 FROM dbo.Member_Ship ms, dbo.Fighter_Public fp, dbo.Method m, dbo.Fighter c, dbo.[D$DYTP] d, dbo.Club_Method cm
                WHERE ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
                  AND ms.FGPB_RWNO_DNRM = fp.RWNO
                  AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
                  AND fp.MTOD_CODE = m.CODE
                  AND fp.COCH_FILE_NO = c.FILE_NO
                  AND cm.CODE = fp.CBMT_CODE
                  AND cm.DAY_TYPE = d.VALU
                  AND ms.FIGH_FILE_NO = @FileNo
                  AND ms.RQRO_RQST_RQID = @OrgnRqid
                  AND ms.RECT_CODE = '004'
            );
            
            IF @InsrCnamStat = '002'
               SET @MsgbText = ISNULL(@MsgbText, N'') + N' ' + @ClubName;
            
            --RAISERROR(@MsgbText, 16, 1);
            
            IF EXISTS (SELECT name FROM sys.databases WHERE name = N'iRoboTech')
	         BEGIN
	            DECLARE @RoboServFileNo BIGINT;
	            SELECT @RoboServFileNo = SERV_FILE_NO
	              FROM iRoboTech.dbo.Service_Robot
	             WHERE ROBO_RBID = 391
	               AND CHAT_ID = @ChatId;
	            
	            IF @RoboServFileNo IS NOT NULL
	               EXEC iRoboTech.dbo.INS_SRRM_P @SRBT_SERV_FILE_NO = @RoboServFileNo, -- bigint
	                   @SRBT_ROBO_RBID = 391, -- bigint
	                   @RWNO = 0, -- bigint
	                   @SRMG_RWNO = NULL, -- bigint
	                   @Ordt_Ordr_Code = NULL, -- bigint
	                   @Ordt_Rwno = NULL, -- bigint
	                   @MESG_TEXT = @MsgbText, -- nvarchar(max)
	                   @FILE_ID = NULL, -- varchar(200)
	                   @FILE_PATH = NULL, -- nvarchar(max)
	                   @MESG_TYPE = '001', -- varchar(3)
	                   @LAT = NULL, -- float
	                   @LON = NULL, -- float
	                   @CONT_CELL_PHON = NULL; -- varchar(11)	            
	         END;
         END;
      END;
      
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
