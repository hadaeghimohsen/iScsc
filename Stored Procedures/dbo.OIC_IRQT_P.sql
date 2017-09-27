SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[OIC_IRQT_P]
	@X XML
AS
BEGIN
   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>162</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 162 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END

   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>163</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 163 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
   DECLARE @ErrorMessage NVARCHAR(MAX);
   BEGIN TRY
   BEGIN TRAN T1
   
	   DECLARE @ActnType VARCHAR(3)
	          ,@Rqid     BIGINT
	          ,@SendExpn VARCHAR(3)
	          ,@CardNumb VARCHAR(50)
	          ,@FngrPrnt VARCHAR(20)
	          ,@TotlSesn SMALLINT
	          ,@MdulName VARCHAR(11)
	          ,@SctnName VARCHAR(11)
	          ,@PrvnCode VARCHAR(3)
	          ,@RegnCode VARCHAR(3)
	          ,@RqtpCode VARCHAR(3)
	          ,@RqttCode VARCHAR(3)
	          ,@FileNo   BIGINT
	          ,@RqroRwno SMALLINT
	          ,@MbspRwno SMALLINT
	          ,@Snid     BIGINT
	          ,@EndDate  DATETIME
	          ,@ExpnCode BIGINT
	          ,@CbmtCode BIGINT;
   	
	   SELECT @ActnType = @X.query('//Request').value('(Request/@actntype)[1]', 'VARCHAR(3)')
	         ,@Rqid     = @X.query('//Request').value('(Request/@rqid)[1]', 'BIGINT')
	         ,@SendExpn = @X.query('//Request').value('(Request/@sendexpn)[1]', 'VARCHAR(3)')
	         ,@CardNumb = @X.query('//Fighter').value('(Fighter/@cardnumb)[1]', 'VARCHAR(50)')
	         ,@FngrPrnt = @X.query('//Fighter').value('(Fighter/@fngrprnt)[1]', 'VARCHAR(20)')
	         ,@TotlSesn = @X.query('//Session').value('(Session/@totlsesn)[1]', 'SMALLINT')
	         ,@ExpnCode = @X.query('//Session').value('(Session/@expncode)[1]', 'BIGINT')
	         --,@CbmtCode = @X.query('//Session').value('(Session/@cbmtcode)[1]', 'BIGINT')
	         ,@MdulName = @X.query('//Request').value('(Request/@mdulname)[1]', 'VARCHAR(11)')
	         ,@SctnName = @X.query('//Request').value('(Request/@sctnname)[1]', 'VARCHAR(11)')
	         ,@EndDate  = @X.query('//Member_Ship').value('(Member_Ship/@enddate)[1]', 'DATETIME');
      
      IF @CardNumb IS NULL
         SET @CardNumb = @FngrPrnt;
      
      -- مشتریان تک جلسه ای
      IF @ActnType = '001'
      BEGIN
         IF NOT EXISTS(
            SELECT *
              FROM Fighter
             WHERE CARD_NUMB_DNRM = @CardNumb
                --OR FNGR_PRNT_DNRM = @FngrPrnt
         )
         BEGIN
            RAISERROR(N'این شماره کارت فاقد اعتبار می باشد لطفا از تب اول برای شارژ کارت استفاده کنید', 16, 1);
            RETURN;
         END
         
         IF (
            SELECT COUNT(FILE_NO)
              FROM Fighter
             WHERE CARD_NUMB_DNRM = @CardNumb
                --OR FNGR_PRNT_DNRM = @FngrPrnt
         ) > 1
         BEGIN
            RAISERROR(N'این شماره کارت در دست چند مشتری می باشد لطفا بررسی کنید', 16, 1);
            RETURN;
         END
         
         IF EXISTS(
            SELECT *
              FROM Member_Ship M, [Session] S, Fighter F
             WHERE M.FIGH_FILE_NO = F.FILE_NO
               AND M.FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO
               AND M.RECT_CODE = S.MBSP_RECT_CODE
               AND M.RWNO = S.MBSP_RWNO
               AND M.RECT_CODE = '004'
               AND M.RWNO = F.MBSP_RWNO_DNRM
               AND DATEDIFF(DAY,M.STRT_DATE, M.END_DATE) >= 1
               AND F.CARD_NUMB_DNRM = S.CARD_NUMB
               AND S.CARD_NUMB = @CardNumb               
         )
         BEGIN
            RAISERROR(N'این شماره کارت برای مشتری چند جلسه ای  می باشد لطفا از منوی صفحه اصلی در قسمت ثبت نام جلسه با مربی اقدام کنید', 16, 1);
            RETURN;
         END
         
         SELECT @RqtpCode = '009'--'016'
               ,@RqttCode = '008'
               ,@PrvnCode = REGN_PRVN_CODE
               ,@RegnCode = REGN_CODE
               ,@FileNo   = FILE_NO
           FROM Fighter
          WHERE CARD_NUMB_DNRM = @CardNumb;
             --OR FNGR_PRNT_DNRM = @FngrPrnt;
         -- ثبت شماره درخواست 
         IF @Rqid IS NULL OR @Rqid = 0
         BEGIN
            EXEC dbo.INS_RQST_P
               @PrvnCode,
               @RegnCode,
               NULL,
               @RqtpCode,
               @RqttCode,
               NULL,
               NULL,
               NULL,
               @Rqid OUT;  
               
            UPDATE Request
               SET MDUL_NAME = @MdulName
                 ,SECT_NAME = @SctnName
             WHERE RQID = @Rqid;                
         END
         
         -- ثبت ردیف درخواست 
         SELECT @RqroRwno = Rwno
           FROM Request_Row
          WHERE RQST_RQID = @Rqid
            AND FIGH_FILE_NO = @FileNo;
              
         IF @RqroRwno IS NULL
         BEGIN
            EXEC INS_RQRO_P
               @Rqid
              ,@FileNo
              ,@RqroRwno OUT;
         END
         
         -- مرحله بعدی ثبت اطلاعات در جدول عضویت
         IF NOT EXISTS(
            SELECT *
              FROM Member_Ship
             WHERE RQRO_RQST_RQID = @Rqid
               AND RQRO_RWNO = @RqroRwno
               AND FIGH_FILE_NO = @FileNo
               AND RECT_CODE = '001'
               AND [TYPE] = '001'
         )
         BEGIN
            INSERT INTO Member_Ship (RQRO_RQST_RQID,RQRO_RWNO, FIGH_FILE_NO, RECT_CODE, [TYPE], STRT_DATE, END_DATE)
            SELECT @Rqid, @RqroRwno, @FileNo, '001', '001', M.STRT_DATE, M.END_DATE
              FROM Member_Ship M, Fighter F
             WHERE M.FIGH_FILE_NO = @FileNo
               AND M.FIGH_FILE_NO = F.FILE_NO
               AND M.RWNO = F.MBSP_RWNO_DNRM
               AND M.[TYPE] = '001'
               AND M.RECT_CODE = '004';
         END
         ELSE 
            UPDATE dbo.Member_Ship
               SET END_DATE = @EndDate
             WHERE RQRO_RQST_RQID = @Rqid
               AND RQRO_RWNO = @RqroRwno
               AND RECT_CODE = '001';
         

         SELECT @MbspRwno = RWNO
           FROM Member_Ship
          WHERE RQRO_RQST_RQID = @Rqid
            AND RQRO_RWNO = @RqroRwno
            AND FIGH_FILE_NO = @FileNo
            AND [TYPE] = '001'
            AND RECT_CODE = '001';

         SELECT TOP 1
                @Snid = SNID
           FROM [Session]
          WHERE MBSP_FIGH_FILE_NO = @FileNo
            AND MBSP_RECT_CODE = '001'
            AND MBSP_RWNO = @MbspRwno
            AND SESN_TYPE = '002'
            AND SNID = (SELECT MAX(SNID)
                             FROM [Session]
                            WHERE MBSP_FIGH_FILE_NO = @FileNo
                              AND MBSP_RECT_CODE = '001'
                              AND MBSP_RWNO = @MbspRwno
                          ); 
         
         IF @Snid IS NULL OR @Snid = 0
         BEGIN
            SET @Snid = dbo.GNRT_NVID_U();
            INSERT INTO [Session] (MBSP_FIGH_FILE_NO, MBSP_RECT_CODE, MBSP_RWNO, SNID, SESN_TYPE, EXPN_CODE, CARD_NUMB, TOTL_SESN, CBMT_CODE)
            SELECT TOP 1 @FileNo, '001', @MbspRwno, @Snid, '002', EXPN_CODE, CARD_NUMB, CASE WHEN @TotlSesn = 0 OR @TotlSesn IS NULL THEN 1 ELSE @TotlSesn END, @CbmtCode
              FROM [Session] S
            WHERE S.MBSP_FIGH_FILE_NO = @FileNo
              AND S.MBSP_RECT_CODE = '004'
              AND S.MBSP_RWNO = (
                 SELECT MBSP_RWNO_DNRM
                   FROM Fighter F
                  WHERE F.FILE_NO = @FileNo
                    --AND F.CARD_NUMB_DNRM = @CardNumb
              )
         END
         ELSE
            UPDATE [Session]
               SET TOTL_SESN = @TotlSesn
                  ,EXPN_CODE = @ExpnCode
             WHERE MBSP_FIGH_FILE_NO = @FileNo
               AND MBSP_RECT_CODE = '001'
               AND MBSP_RWNO = @MbspRwno
               AND SNID = @Snid;
      END
      
      -- مشتریان چند جلسه ای
      ELSE IF @ActnType = '002'
      BEGIN
         IF NOT EXISTS(
            SELECT *
              FROM Fighter
             WHERE CARD_NUMB_DNRM = @CardNumb
                OR FNGR_PRNT_DNRM = @FngrPrnt
         )
         BEGIN
            RAISERROR(N'این شماره کارت فاقد اعتبار می باشد لطفا از تب اول برای شارژ کارت استفاده کنید', 16, 1);
            RETURN;
         END
         
         IF (
            SELECT COUNT(FILE_NO)
              FROM Fighter
             WHERE CARD_NUMB_DNRM = @CardNumb
                OR FNGR_PRNT_DNRM = @FngrPrnt
         ) > 1
         BEGIN
            RAISERROR(N'این شماره کارت در دست چند مشتری می باشد لطفا بررسی کنید', 16, 1);
            RETURN;
         END
         
         IF EXISTS(
            SELECT *
              FROM Member_Ship M, [Session] S, Fighter F
             WHERE M.FIGH_FILE_NO = F.FILE_NO
               AND M.FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO
               AND M.RECT_CODE = S.MBSP_RECT_CODE
               AND M.RWNO = S.MBSP_RWNO
               AND M.RECT_CODE = '004'
               AND M.RWNO = F.MBSP_RWNO_DNRM
               AND DATEDIFF(DAY,M.STRT_DATE, M.END_DATE) = 0
               AND F.CARD_NUMB_DNRM = S.CARD_NUMB
               AND S.CARD_NUMB = @CardNumb               
         )
         BEGIN
            RAISERROR(N'این شماره کارت برای مشتری تک جلسه ای  می باشد لطفا از منوی صفحه اصلی در قسمت ثبت نام جلسه بدون مربی اقدام کنید', 16, 1);
            RETURN;
         END
         
         IF @EndDate = '1900-01-01' BEGIN RAISERROR(N'ورود تاریخ پایان جلسات الزامی می باشد', 16, 1); RETURN; END
         
         SELECT @RqtpCode = '009'--'016'
               ,@RqttCode = '008'
               ,@PrvnCode = REGN_PRVN_CODE
               ,@RegnCode = REGN_CODE
               ,@FileNo   = FILE_NO
               ,@CbmtCode = CBMT_CODE_DNRM
           FROM Fighter
          WHERE CARD_NUMB_DNRM = @CardNumb
             OR FNGR_PRNT_DNRM = @FngrPrnt;
         -- ثبت شماره درخواست 
         IF @Rqid IS NULL OR @Rqid = 0
         BEGIN
            EXEC dbo.INS_RQST_P
               @PrvnCode,
               @RegnCode,
               NULL,
               @RqtpCode,
               @RqttCode,
               NULL,
               NULL,
               NULL,
               @Rqid OUT;  
               
            UPDATE Request
               SET MDUL_NAME = @MdulName
                  ,SECT_NAME = @SctnName
                  ,SEND_EXPN = @SendExpn
             WHERE RQID = @Rqid;                
         END
         
         UPDATE Request
            SET SEND_EXPN = @SendExpn
          WHERE RQID = @Rqid;                

         
         -- ثبت ردیف درخواست 
         SELECT @RqroRwno = Rwno
           FROM Request_Row
          WHERE RQST_RQID = @Rqid
            AND FIGH_FILE_NO = @FileNo;
              
         IF @RqroRwno IS NULL
         BEGIN
            EXEC INS_RQRO_P
               @Rqid
              ,@FileNo
              ,@RqroRwno OUT;
         END
         
         -- مرحله بعدی ثبت اطلاعات در جدول عضویت
         IF NOT EXISTS(
            SELECT *
              FROM Member_Ship
             WHERE RQRO_RQST_RQID = @Rqid
               AND RQRO_RWNO = @RqroRwno
               AND FIGH_FILE_NO = @FileNo
               AND RECT_CODE = '001'
               AND [TYPE] = '001'
         )
         BEGIN
            INSERT INTO Member_Ship (RQRO_RQST_RQID,RQRO_RWNO, FIGH_FILE_NO, RECT_CODE, [TYPE], STRT_DATE, END_DATE)
            SELECT @Rqid, @RqroRwno, @FileNo, '001', '001', M.STRT_DATE, @EndDate--M.END_DATE
              FROM Member_Ship M, Fighter F
             WHERE M.FIGH_FILE_NO = @FileNo
               AND M.FIGH_FILE_NO = F.FILE_NO
               AND M.RWNO = F.MBSP_RWNO_DNRM
               AND M.[TYPE] = '001'
               AND M.RECT_CODE = '004';
         END
         ELSE
            UPDATE dbo.Member_Ship
               SET END_DATE = @EndDate
             WHERE RQRO_RQST_RQID = @Rqid
               AND RQRO_RWNO = @RqroRwno
               AND RECT_CODE = '001';         

         SELECT @MbspRwno = RWNO
           FROM Member_Ship
          WHERE RQRO_RQST_RQID = @Rqid
            AND RQRO_RWNO = @RqroRwno
            AND FIGH_FILE_NO = @FileNo
            AND [TYPE] = '001'
            AND RECT_CODE = '001';

         SELECT TOP 1
                @Snid = SNID
           FROM [Session]
          WHERE MBSP_FIGH_FILE_NO = @FileNo
            AND MBSP_RECT_CODE = '001'
            AND MBSP_RWNO = @MbspRwno
            AND SESN_TYPE = '002'
            AND SNID = (SELECT MAX(SNID)
                             FROM [Session]
                            WHERE MBSP_FIGH_FILE_NO = @FileNo
                              AND MBSP_RECT_CODE = '001'
                              AND MBSP_RWNO = @MbspRwno
                          ); 
                          
         IF @Snid IS NULL OR @Snid = 0
         BEGIN
            SET @Snid = dbo.GNRT_NVID_U();
            INSERT INTO [Session] (MBSP_FIGH_FILE_NO, MBSP_RECT_CODE, MBSP_RWNO, SNID, SESN_TYPE, EXPN_CODE, CARD_NUMB, TOTL_SESN, CBMT_CODE)
            SELECT TOP 1 @FileNo, '001', @MbspRwno, @Snid, '002', EXPN_CODE, CARD_NUMB, CASE WHEN @TotlSesn = 0 OR @TotlSesn IS NULL THEN 1 ELSE @TotlSesn END, @CbmtCode
              FROM [Session] S
            WHERE S.MBSP_FIGH_FILE_NO = @FileNo
              AND S.MBSP_RECT_CODE = '004'
              AND S.MBSP_RWNO = (
                 SELECT MBSP_RWNO_DNRM
                   FROM Fighter F
                  WHERE F.FILE_NO = @FileNo
            );
         END
         ELSE
         BEGIN
            /*IF EXISTS(
               SELECT *
                 FROM dbo.Fighter f, dbo.Member_Ship m, dbo.Session s
                WHERE f.FILE_NO = m.FIGH_FILE_NO
                  AND f.MBSP_RWNO_DNRM = m.RWNO
                  AND m.RECT_CODE = '004'
                  AND m.FIGH_FILE_NO = s.MBSP_FIGH_FILE_NO
                  AND m.RWNO = s.MBSP_RWNO
                  AND m.RECT_CODE = s.MBSP_RECT_CODE
                  AND s.TOTL_SESN - ISNULL(s.SUM_MEET_HELD_DNRM, 0) > 0
                  AND s.EXPN_CODE <> @ExpnCode
            )
            BEGIN
               RAISERROR(N'تعداد جلسات هنرجو به پایان نرسیده لطفا بعد از اتمام کلیه جلسات با نرخ جدید اعلام هزینه کنید', 16, 1);
               RETURN;
            END*/
            UPDATE [Session]
               SET TOTL_SESN = CASE @SendExpn WHEN '001' THEN @TotlSesn ELSE 0 END
                  ,EXPN_CODE = @ExpnCode
                  ,CBMT_CODE = @CbmtCode
             WHERE MBSP_FIGH_FILE_NO = @FileNo
               AND MBSP_RECT_CODE = '001'
               AND MBSP_RWNO = @MbspRwno
               AND SNID = @Snid;
         END
      END	   
      
   COMMIT TRAN T1
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
