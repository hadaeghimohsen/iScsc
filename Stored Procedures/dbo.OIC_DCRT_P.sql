SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[OIC_DCRT_P]
	@X XML
AS
BEGIN
   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>186</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 186 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END

   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>187</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 187 سطوح امینتی', -- Message text.
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
	          --,@CardNumb VARCHAR(50)
 	          ,@ExpnCode BIGINT
	          ,@TotlSesn SMALLINT
	          ,@CbmtCode BIGINT
	          ,@FngrPrnt VARCHAR(20)
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
	          ,@EndDate  DATETIME;
   	
	   SELECT @ActnType = @X.query('//Request').value('(Request/@actntype)[1]', 'VARCHAR(3)')
	         ,@Rqid     = @X.query('//Request').value('(Request/@rqid)[1]', 'BIGINT')
	         --,@CardNumb = @X.query('//Fighter').value('(Fighter/@cardnumb)[1]', 'VARCHAR(50)')
	         ,@FngrPrnt = @X.query('//Fighter').value('(Fighter/@fngrprnt)[1]', 'VARCHAR(20)')
	         --,@TotlSesn = @X.query('//Session').value('(Session/@totlsesn)[1]', 'SMALLINT')
	         ,@MdulName = @X.query('//Request').value('(Request/@mdulname)[1]', 'VARCHAR(11)')
	         ,@SctnName = @X.query('//Request').value('(Request/@sctnname)[1]', 'VARCHAR(11)')
	         ,@EndDate  = @X.query('//Member_Ship').value('(Member_Ship/@enddate)[1]', 'DATETIME');
      

      -- مشتریان چند جلسه ای ترکیبی
      IF @ActnType = '003'
      BEGIN
         IF NOT EXISTS(
            SELECT *
              FROM Fighter
             WHERE FNGR_PRNT_DNRM = @FngrPrnt
         )
         BEGIN
            RAISERROR(N'این شماره کارت فاقد اعتبار می باشد لطفا از تب اول برای شارژ کارت استفاده کنید', 16, 1);
            RETURN;
         END
         
         IF (
            SELECT COUNT(FILE_NO)
              FROM Fighter
             WHERE FNGR_PRNT_DNRM = @FngrPrnt
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
               AND S.CARD_NUMB = @FngrPrnt               
         )
         BEGIN
            RAISERROR(N'این شماره کارت برای مشتری تک جلسه ای  می باشد لطفا از منوی صفحه اصلی در قسمت ثبت نام جلسه بدون مربی اقدام کنید', 16, 1);
            RETURN;
         END
         
         IF @EndDate = '1900-01-01' BEGIN RAISERROR(N'ورود تاریخ پایان جلسات الزامی می باشد', 16, 1); RETURN; END
         
         SELECT @RqtpCode = '019'
               ,@RqttCode = '008'
               ,@PrvnCode = REGN_PRVN_CODE
               ,@RegnCode = REGN_CODE
               ,@FileNo   = FILE_NO
           FROM Fighter
          WHERE FNGR_PRNT_DNRM = @FngrPrnt;
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
            SELECT @Rqid, @RqroRwno, @FileNo, '001', '001', M.STRT_DATE, @EndDate--M.END_DATE
              FROM Member_Ship M, Fighter F
             WHERE M.FIGH_FILE_NO = @FileNo
               AND M.FIGH_FILE_NO = F.FILE_NO
               AND M.RWNO = F.MBSP_RWNO_DNRM
               AND M.[TYPE] = '001'
               AND M.RECT_CODE = '004';
         END
         

         SELECT @MbspRwno = RWNO
           FROM Member_Ship
          WHERE RQRO_RQST_RQID = @Rqid
            AND RQRO_RWNO = @RqroRwno
            AND FIGH_FILE_NO = @FileNo
            AND [TYPE] = '001'
            AND RECT_CODE = '001';
         
         /* آخرین رکورد مربوط به جلسات ثبت نام شده کاربر آورده شود*/
         IF NOT EXISTS(
            SELECT * 
              FROM dbo.Session S, dbo.Member_Ship M
             WHERE S.MBSP_FIGH_FILE_NO = M.FIGH_FILE_NO
               AND S.MBSP_RECT_CODE = M.RECT_CODE
               AND S.MBSP_RWNO = M.RWNO
               AND M.RQRO_RQST_RQID = @Rqid
               AND M.RQRO_RWNO = @RqroRwno
         )
         BEGIN
            IF NOT EXISTS(
               SELECT *
                 FROM dbo.Session S, Member_Ship M, Fighter F
                WHERE M.FIGH_FILE_NO = @FileNo
                  AND M.FIGH_FILE_NO = F.FILE_NO
                  AND M.RWNO = F.MBSP_RWNO_DNRM
                  AND M.[TYPE] = '001'
                  AND M.RECT_CODE = '004'
                  AND M.FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO
                  AND M.RWNO = S.MBSP_RWNO
                  AND M.RECT_CODE = S.MBSP_RECT_CODE
                  AND S.SESN_TYPE = '003'
            )
            BEGIN
               RAISERROR(N'این هنرجو سابقه ثبت نام ترکیبی ندارد. لطفا بررسی کنید', 16, 1);
               RETURN;
            END

            INSERT INTO Session (MBSP_FIGH_FILE_NO, MBSP_RECT_CODE, MBSP_RWNO, EXPN_CODE, SNID, SESN_TYPE, TOTL_SESN, CARD_NUMB, CBMT_CODE, SESN_SNID)
            SELECT S.MBSP_FIGH_FILE_NO, '001', @MbspRwno, S.EXPN_CODE, dbo.GNRT_NVID_U(), S.SESN_TYPE, /*s.TOTL_SESN - ISNULL(S.SUM_MEET_HELD_DNRM, 0)*/ 0, s.CARD_NUMB, s.CBMT_CODE, s.SNID
              FROM dbo.Session S, Member_Ship M, Fighter F
             WHERE F.RQST_RQID = @Rqid
               AND M.FIGH_FILE_NO = F.FILE_NO
               AND M.RWNO = F.MBSP_RWNO_DNRM
               AND M.[TYPE] = '001'
               AND M.RECT_CODE = '004'
               AND M.FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO
               AND M.RWNO = S.MBSP_RWNO
               AND M.RECT_CODE = S.MBSP_RECT_CODE
               AND S.TOTL_SESN - ISNULL(S.SUM_MEET_HELD_DNRM, 0) > 0;
         END
         ELSE
         BEGIN
            DECLARE C$Sessions CURSOR FOR
            SELECT r.query('.').value('(Session/@snid)[1]', 'BIGINT')
                  ,r.query('.').value('(Session/@expncode)[1]', 'BIGINT')
                  ,r.query('.').value('(Session/@totlsesn)[1]', 'SMALLINT')
                  ,r.query('.').value('(Session/@cbmtcode)[1]', 'BIGINT')
            FROM @X.nodes('//Session') T(r)
            
            OPEN C$Sessions;
            Fetch_C$Sessions:
            FETCH NEXT FROM C$Sessions INTO @Snid, @ExpnCode, @TotlSesn, @CbmtCode;
            
            IF @@FETCH_STATUS <> 0
               GOTO End_C$Session;

            IF @ExpnCode = 0 BEGIN CLOSE C$Sessions; DEALLOCATE C$Sessions; RAISERROR(N'ورود شرکت در جلسه الزامی می باشد', 16, 1); RETURN; END
            --IF @TotlSesn = 0 BEGIN CLOSE C$Sessions; DEALLOCATE C$Sessions; RAISERROR(N'ورود تعداد جلسات الزامی می باشد', 16, 1); RETURN; END
            IF @TotlSesn < 0 BEGIN CLOSE C$Sessions; DEALLOCATE C$Sessions; RAISERROR(N'تعداد جلسات باید بیشتر یک جلسه باشد', 16, 1); RETURN; END
            IF @CbmtCode = 0 BEGIN CLOSE C$Sessions; DEALLOCATE C$Sessions; RAISERROR(N'ساعت برنامه کلاسی مشخص نشده است', 16, 1); RETURN; END
       
            IF (
               SELECT COUNT(Snid)
                 FROM dbo.Session
                WHERE MBSP_FIGH_FILE_NO = @FileNo
                  AND MBSP_RECT_CODE = '001'
                  AND MBSP_RWNO = @MbspRwno
                  AND SESN_TYPE = '003'
                  AND CBMT_CODE = @CbmtCode
                  AND SNID <> @Snid
            ) >= 1
            BEGIN
               CLOSE C$Sessions;
               DEALLOCATE C$Sessions;
               RAISERROR(N'برنامه کلاسی وارد شده قبلا در لیست وجود دارد. لطفا اصلاح کنید', 16, 1);            
               RETURN;
            END
               
            IF @Snid IS NULL OR @Snid = 0
            BEGIN
               SET @Snid = dbo.GNRT_NVID_U();
               INSERT INTO [Session] (MBSP_FIGH_FILE_NO, MBSP_RECT_CODE, MBSP_RWNO, SNID, SESN_TYPE, EXPN_CODE, CARD_NUMB, TOTL_SESN, CBMT_CODE)
               VALUES(@FileNo, '001', @MbspRwno, @Snid, '003', @ExpnCode, @FngrPrnt, @TotlSesn, @CbmtCode);
            END
            ELSE
               IF EXISTS(
                  SELECT *
                    FROM dbo.Session s
                   WHERE s.MBSP_FIGH_FILE_NO = @FileNo
                     AND s.MBSP_RECT_CODE = '001'
                     AND s.MBSP_RWNO = @MbspRwno
                     AND s.SNID = @Snid
                     AND EXISTS(
                        SELECT *
                          FROM dbo.Session St, dbo.Fighter f
                         WHERE st.MBSP_FIGH_FILE_NO = @FileNo
                           AND st.MBSP_RECT_CODE = '004'
                           AND st.MBSP_RWNO = f.MBSP_RWNO_DNRM
                           AND st.MBSP_FIGH_FILE_NO = f.FILE_NO
                           AND s.CBMT_CODE = st.CBMT_CODE
                           AND st.TOTL_SESN - ISNULL(st.SUM_MEET_HELD_DNRM, 0) < @TotlSesn                         
                     )
               )
               BEGIN
                  CLOSE C$Sessions;
                  DEALLOCATE C$Sessions;
                  RAISERROR(N'تعداد جلسات باقیمانده از ساعت کلاسی کمتر از تعداد جلسات انصرافی می باشد. لطفا بررسی و اصلاح کنید', 16, 1);            
                  RETURN;                  
               END
               
               UPDATE [Session]
                  SET EXPN_CODE = @ExpnCode
                     ,CARD_NUMB = @FngrPrnt
                     ,TOTL_SESN = @TotlSesn
                     ,CBMT_CODE = @CbmtCode
                WHERE MBSP_FIGH_FILE_NO = @FileNo
                  AND MBSP_RECT_CODE = '001'
                  AND MBSP_RWNO = @MbspRwno
                  AND SNID = @Snid;
            
            GOTO Fetch_C$Sessions;
            End_C$Session:
            CLOSE C$Sessions;
            DEALLOCATE C$Sessions;
         END
         
         End_Work:
         PRINT 'Done!';
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
