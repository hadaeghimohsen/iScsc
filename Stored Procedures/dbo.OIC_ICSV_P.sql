SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[OIC_ICSV_P]
	@X XML
AS
BEGIN
	DECLARE @AP BIT
       ,@AccessString VARCHAR(250);

   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>189</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 189 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
	DECLARE @ErrorMessage NVARCHAR(MAX);

   BEGIN TRY
      BEGIN TRAN T1;
      
      DECLARE @Rqid BIGINT
             ,@RemnTotlSesn SMALLINT;             
	          
	   SELECT @Rqid = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT');

      INSERT INTO Member_Ship (RQRO_RQST_RQID, RQRO_RWNO, FIGH_FILE_NO, RECT_CODE, [TYPE], STRT_DATE, END_DATE)
      SELECT RQRO_RQST_RQID, RQRO_RWNO, FIGH_FILE_NO, '004', [TYPE], STRT_DATE, END_DATE
        FROM Member_Ship
       WHERE RQRO_RQST_RQID = @Rqid
         AND RECT_CODE = '001';
      
      DECLARE @OldMbspRwno SMALLINT
             ,@NewMbspRwno SMALLINT
             ,@MbspFighFileNo BIGINT;
      
      SELECT @MbspFighFileNo = FIGH_FILE_NO
            ,@NewMbspRwno = RWNO
        FROM Member_Ship
       WHERE RQRO_RQST_RQID = @Rqid
         AND RECT_CODE = '004';         
     
      SELECT @OldMbspRwno = RWNO
        FROM Member_Ship
       WHERE RQRO_RQST_RQID = @Rqid
         AND RECT_CODE = '001';       
      
      DECLARE C$Sessions CURSOR FOR
         SELECT S.EXPN_CODE, 
                S.TOTL_SESN, 
                S.CARD_NUMB, 
                s.CBMT_CODE, 
                s.SNID,
                s.COCH_FILE_NO_DNRM
                --s.SESN_SNID
           FROM Member_Ship m, dbo.Session s
          WHERE m.RQRO_RQST_RQID = @Rqid
            AND m.FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO
            AND m.RECT_CODE = S.MBSP_RECT_CODE
            AND m.RWNO = S.MBSP_RWNO
            AND m.RECT_CODE = '001';
      
      DECLARE	
	      @ExpnCode [bigint] ,
	      @TotlSesn [smallint] ,
	      @CardNumb [varchar](50) ,
	      @CbmtCode [bigint] ,
	      @SesnSnid BIGINT,
	      @CochFileNo BIGINT;
	      
	   
	   DECLARE @TotlAttnNumb INT = 0;
	   
      OPEN C$Sessions;
      Start_C$Sessions:
      FETCH NEXT FROM C$Sessions INTO @ExpnCode, @TotlSesn, @CardNumb, @CbmtCode, @SesnSnid, @CochFileNo;
      
      IF @@FETCH_STATUS <> 0
         GOTO End_C$Sessions;

      /*SELECT @RemnTotlSesn = S.TOTL_SESN - ISNULL(S.SUM_MEET_HELD_DNRM, 0)
        FROM Fighter F, Member_Ship M, [Session] S
       WHERE F.FILE_NO = M.FIGH_FILE_NO
         AND M.FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO
         AND M.RECT_CODE = S.MBSP_RECT_CODE
         AND M.RWNO = S.MBSP_RWNO
         AND M.RECT_CODE = '004'
         AND M.RWNO = @NewMbspRwno - 1
         AND S.SNID = @SesnSnid;*/      
         
      INSERT INTO [Session] (MBSP_FIGH_FILE_NO, MBSP_RECT_CODE, MBSP_RWNO, SNID, SESN_TYPE, TOTL_SESN, CARD_NUMB, EXPN_CODE, CBMT_CODE)
      SELECT MBSP_FIGH_FILE_NO, '004', @NewMbspRwno, dbo.GNRT_NVID_U(), SESN_TYPE, TOTL_SESN + ISNULL(@RemnTotlSesn, 0), CARD_NUMB, EXPN_CODE, CBMT_CODE
        FROM [Session] 
       WHERE MBSP_FIGH_FILE_NO = @MbspFighFileNo
         AND MBSP_RECT_CODE = '001'
         AND MBSP_RWNO = @OldMbspRwno
         AND ISNULL(SNID, 0) = ISNULL(@SesnSnid, 0);
      
      -- 1396/05/09 * برای بدست آوردن اطلاعات تعداد کل جلسات مربوط به جلسات ترکیبی
      SELECT @TotlAttnNumb += TOTL_SESN
        FROM dbo.Session
       WHERE MBSP_FIGH_FILE_NO = @MbspFighFileNo
         AND MBSP_RECT_CODE = '001'
         AND MBSP_RWNO = @OldMbspRwno
         AND EXPN_CODE = @ExpnCode;
      
      -- بروزرسانی اطلاعات مربی برای هزینه
      UPDATE Payment_Detail
         SET FIGH_FILE_NO = @CochFileNo
       WHERE PYMT_RQST_RQID = @Rqid
         AND EXPN_CODE = @ExpnCode;
      
      GOTO Start_C$Sessions;
      End_C$Sessions:
      CLOSE C$Sessions;
      DEALLOCATE C$Sessions;
      
      -- 1396/05/09 * ذخیره کردن اطلاعات کل جلسات
      UPDATE dbo.Member_Ship
         SET NUMB_OF_ATTN_MONT = @TotlAttnNumb
       WHERE RQRO_RQST_RQID = @Rqid;

      
      UPDATE Payment_Detail
         SET PAY_STAT = '002'
            ,RCPT_MTOD = @x.query('//Payment_Detail[@code=sql:column("Code")]').value('(Payment_Detail/@rcptmtod)[1]', 'VARCHAR(3)')
       WHERE PYMT_RQST_RQID = @Rqid
         AND PAY_STAT = '001'
         AND @x.query('//Payment').value('(Payment/@setondebt)[1]', 'BIT') = 0;

      -- بروزرسانی اطلاعات مربی برای هزینه
      UPDATE pd
         SET FIGH_FILE_NO = s.COCH_FILE_NO_DNRM
            ,CBMT_CODE_DNRM = s.CBMT_CODE
        FROM Payment_Detail pd, dbo.Session s, dbo.Member_Ship m
       WHERE pd.PYMT_RQST_RQID = @Rqid
         AND pd.EXPN_CODE = s.EXPN_CODE
         AND s.MBSP_FIGH_FILE_NO = m.FIGH_FILE_NO
         AND s.MBSP_RECT_CODE = m.RECT_CODE
         AND s.MBSP_RWNO = m.RWNO
         AND m.RQRO_RQST_RQID = pd.PYMT_RQST_RQID;
      
      UPDATE Request
         SET RQST_STAT = '002'
       WHERE RQID = @Rqid;
      
      DECLARE @FileNo BIGINT,
              @RegnCode VARCHAR(3),
              @PrvnCode VARCHAR(3);
      SELECT @FileNo = FIGH_FILE_NO
            ,@RegnCode = REGN_CODE
            ,@PrvnCode = REGN_PRVN_CODE
        FROM dbo.Request_Row
       WHERE RQST_RQID = @Rqid;
      
      -- 1396/05/07 * اگر هنرجو نوع غیری از اعضا با جسات مدتدار باشد باید گزینه تغییر مشخصات عمومی سیستمی ثبت گردد
      IF EXISTS(
         SELECT *
           FROM dbo.Fighter a, dbo.Fighter_Public b
          WHERE a.FILE_NO = b.FIGH_FILE_NO
            AND a.FGPB_RWNO_DNRM = b.RWNO
            AND a.FILE_NO = @FileNo            
            AND b.RECT_CODE = '004'            
            AND a.FGPB_TYPE_DNRM = '009'
            AND b.TYPE != '009'
      )
      BEGIN
         -- اگر تغییری در سبک و رسته ایجاد نشده باشد باید تغییر مشخصات عمومی مجزایی برای ثبت ساعت کلاسی ذخیره کنیم
         SET @X = N'<Process><Request rqstrqid="" rqtpcode="002" rqttcode="004" regncode="" prvncode="" rqstdesc="درخواست ویرایش تغییر نوع عضویت هنرجو"><Request_Row fileno=""></Request_Row></Request></Process>';
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
            SET TYPE = '009'
          WHERE RQRO_RQST_RQID = @Rqid
            AND FIGH_FILE_NO = @FileNo;
         
         SET @X = '<Process><Request rqid="" rqtpcode="002" rqttcode="004" regncode="" prvncode=""><Request_Row fileno=""></Request_Row></Request></Process>';
         SET @X.modify('replace value of (/Process/Request/@rqid)[1] with sql:variable("@Rqid")');
         SET @X.modify('replace value of (/Process/Request/@regncode)[1] with sql:variable("@RegnCode")');
         SET @X.modify('replace value of (/Process/Request/@prvncode)[1] with sql:variable("@PrvnCode")');
         SET @X.modify('replace value of (/Process/Request/Request_Row/@fileno)[1] with sql:variable("@FileNo")');
         EXEC PBL_SAVE_F @X;
      END

      UPDATE dbo.Session_Meeting
         SET END_TIME = GETDATE()
       WHERE MBSP_FIGH_FILE_NO = @FileNo
         AND END_TIME IS NULL;
      
      UPDATE dbo.Attendance
         SET EXIT_TIME = GETDATE()
       WHERE FIGH_FILE_NO = @FileNo
         AND EXIT_TIME IS NULL;
             
      COMMIT TRAN T1;
   END TRY
   BEGIN CATCH
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T1;
   END CATCH
END
GO
