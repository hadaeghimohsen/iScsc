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

      -- 1396/08/18 * اگر درون تخفیفات مشترک گزینه ای باشد که مبلغ تخفیف مابه التفاوت وجود داشته باشد بایستی 
      -- مبلغ بدهی قبلی را به عنوان تخفیف مابه التفاوت لحاظ شود و تسویه حساب کامل انجام شود         
      --IF EXISTS(
      --   SELECT *
      --     FROM dbo.Payment_Discount
      --    WHERE AMNT_TYPE = '004'   
      --      AND PYMT_RQST_RQID = @Rqid       
      --)
      BEGIN
         -- 1396/08/18 * بدست آوردن درخواست ثبت نام قبلی
         DECLARE @OldRqid BIGINT
         SELECT TOP 1 @OldRqid = RQID
           FROM dbo.[VF$Request_Changing](@FileNo)
          WHERE RQTT_CODE != '004'
            AND RQTP_CODE IN ('001' , '009')
       ORDER BY SAVE_DATE DESC;
         -- اگر مشترک نسبت به دوره قبلی بدهکار باشد
         IF EXISTS(
            SELECT *
              FROM dbo.Payment
             WHERE RQST_RQID = @OldRqid
               AND (SUM_EXPN_PRIC + SUM_EXPN_EXTR_PRCT) - (SUM_RCPT_EXPN_PRIC + ISNULL(SUM_PYMT_DSCN_DNRM, 0)) > 0
         )
         BEGIN
            INSERT INTO dbo.Payment_Discount ( PYMT_CASH_CODE ,PYMT_RQST_RQID ,RQRO_RWNO ,RWNO ,AMNT ,AMNT_TYPE ,STAT ,PYDS_DESC )
            SELECT CASH_CODE, RQST_RQID, 1, 0, (SUM_EXPN_PRIC + SUM_EXPN_EXTR_PRCT) - (SUM_RCPT_EXPN_PRIC + ISNULL(SUM_PYMT_DSCN_DNRM, 0)), '004', '002', N'کسر مبلغ مابه التفاوت بدهی شهریه بابت جابه جایی کلاس'
              FROM dbo.Payment
             WHERE RQST_RQID = @OldRqid
               AND (SUM_EXPN_PRIC + SUM_EXPN_EXTR_PRCT) - (SUM_RCPT_EXPN_PRIC + ISNULL(SUM_PYMT_DSCN_DNRM, 0)) > 0;
            
            UPDATE dbo.Payment_Detail
               SET PAY_STAT = '002'
             WHERE PYMT_RQST_RQID = @OldRqid;
         END
      END

      
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
            AND (ISNULL(MTOD_CODE, 0) <> @MtodCode
               OR ISNULL(CTGY_CODE, 0) <> @CtgyCode )
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
               ,TYPE = CASE [TYPE] WHEN '009' THEN '001' ELSE [TYPE] END
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
      
      DECLARE @CellPhon VARCHAR(11)
             ,@SexType VARCHAR(3)
             ,@FrstName NVARCHAR(250)
             ,@LastName NVARCHAR(250);
      
      SELECT @CellPhon = f.CELL_PHON_DNRM
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
                ,@InsrFnamStat VARCHAR(3);
                
         SELECT @MsgbStat = STAT
               ,@MsgbText = MSGB_TEXT
               ,@ClubName = CLUB_NAME
               ,@InsrCnamStat = INSR_CNAM_STAT
               ,@InsrFnamStat = INSR_FNAM_STAT
           FROM dbo.Message_Broadcast
          WHERE MSGB_TYPE = '007';
         
         IF @MsgbStat = '002' 
         BEGIN
            IF @InsrFnamStat = '002'
               SET @MsgbText = (SELECT DOMN_DESC FROM dbo.[D$SXDC] WHERE VALU = @SexType) + N' ' + @FrstName + N' ' + @LastName + N' ' + @MsgbText;
            
            IF @InsrCnamStat = '002'
               SET @MsgbText = @MsgbText + N' ' + @ClubName;
               
            DECLARE @XMsg XML;
            SELECT @XMsg = (
               SELECT 5 AS '@subsys',
                      '002' AS '@linetype',
                      (
                        SELECT @CellPhon AS '@phonnumb',
                               (
                                   SELECT '007' AS '@type' 
                                          ,@MsgbText
                                      FOR XML PATH('Message'), TYPE 
                               ) 
                           FOR XML PATH('Contact'), TYPE
                      )
                 FOR XML PATH('Contacts'), ROOT('Process')                            
            );
            EXEC dbo.MSG_SEND_P @X = @XMsg -- xml
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
