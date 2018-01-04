SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_ATTN_P]
	@Club_Code BIGINT,
	@Figh_File_No BIGINT,
	@Attn_Date DATE,
	@CochFileNo BIGINT,	
	@Attn_TYPE VARCHAR(3),
	@MbspRwno SMALLINT
AS
BEGIN
   BEGIN TRY
   BEGIN TRAN INS_ATTN_P_T
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>72</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 72 سطوح امینتی : شما مجوز درج اطلاعات حضور و غیاب را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
   DECLARE @Type VARCHAR(3);
   IF @Club_Code IS NULL
   BEGIN
      SELECT @Club_Code = CLUB_CODE_DNRM
            ,@Type = FGPB_TYPE_DNRM
        FROM Fighter
       WHERE FILE_NO = @Figh_File_No;
      
      IF @Club_Code IS NULL
      BEGIN
         SELECT TOP 1 
                @Club_Code = CLUB_CODE
           FROM dbo.Club_Method
          WHERE @Figh_File_No = COCH_FILE_NO
            AND MTOD_STAT = '002';
         
         IF @Club_Code IS NULL AND @Type != '004'
         BEGIN
            RAISERROR ( N'خطا 1 - این شماره پرونده مربی به هیچ باشگاه و برنامه کلاسی باشگاه متصل نیست', -- Message text.
               16, -- Severity.
               1 -- State.
               );            
         END
         ELSE
         BEGIN
            SELECT TOP 1 @Club_Code = CLUB_CODE
              FROM dbo.V#UCFGA
         END
      END
   END
   
   IF @Attn_Date IS NULL
      SET @Attn_Date = GETDATE();
   IF NOT EXISTS(SELECT * FROM Fighter WHERE CONF_STAT = '002' AND FILE_NO = @Figh_File_No)
      RAISERROR ( N'خطا 2 - این شماره پرونده وجود خارجی ندارد', -- Message text.
               16, -- Severity.
               1 -- State.
               );
   
   
   IF @Attn_TYPE = '005' -- حضوری با مربی دیگر بدون قید و شرط
   BEGIN
      IF ISNULL(@CochFileNo, 0) = 0
      BEGIN
         RAISERROR ( N'خطا 3 - برای ثبت حضوری نیاز به نام مربی می باشد', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      END
   END
   ELSE -- برای بقیه حالت ها
   BEGIN
      SELECT @CochFileNo = COCH_FILE_NO_DNRM, 
             @MbspRwno   = ISNULL(@MbspRwno, MBSP_RWNO_DNRM)
        FROM dbo.Fighter
       WHERE FILE_NO = @Figh_File_No
         AND FGPB_TYPE_DNRM NOT IN ('002', '003');
   END
   
   -- اگر خروج دستی ثبت شده باشد بدون هیچ گونه بررسی خروج زده شود
   IF @Attn_TYPE IN ( '003' )
      GOTO L$ATTN;
   
   DECLARE @NameDnrm NVARCHAR(500)
          ,@EndDate VARCHAR(10)
          ,@SexDesc NVARCHAR(10)
          ,@MessageShow NVARCHAR(MAX)
          ,@StrtDateStr VARCHAR(10)
          --,@EndDate DATE
          ,@NumbOfAttnMont INT
          ,@SumAttnMontDnrm INT;
   
   SELECT @NameDnrm = NAME_DNRM
         ,@EndDate = dbo.GET_MTOS_U(MBSP_END_DATE)
         ,@SexDesc = sxdc.DOMN_DESC
         ,@StrtDateStr = dbo.GET_MTOS_U(MBSP_STRT_DATE)
         ,@NumbOfAttnMont = M.NUMB_OF_ATTN_MONT
         ,@SumAttnMontDnrm = M.SUM_ATTN_MONT_DNRM
         --,@EndDate = MBSP_END_DATE
     FROM dbo.Fighter F, dbo.D$SXDC sxdc, dbo.Member_Ship M
    WHERE F.FILE_NO = @Figh_File_No
      AND F.FILE_NO = M.FIGH_FILE_NO
      --AND F.MBSP_RWNO_DNRM = M.RWNO
      AND m.RWNO = @MbspRwno
      AND M.RECT_CODE = '004'
      AND F.SEX_TYPE_DNRM = sxdc.VALU;
   
   -- پایان مهلت بدهی هنرجو
   IF dbo.CHK_DEBT_U('<Fighter fileno="' + CAST(@Figh_File_No AS VARCHAR(14)) + '"/>') = 0
   BEGIN
      SET @MessageShow = N'هشدار!!!' + CHAR(10) + 
                         @SexDesc + N' ' + @NameDnrm + CHAR(10) +
                         N'تاریخ شروع ' + @StrtDateStr + N' تاریخ پایان ' + @EndDate + CHAR(10) +
                         N' مهلت پرداخت بدهی ما به پایان رسیده است.' + CHAR(10) +
                         N'لطفا جهت تسویه بدهی خود اقدام فرمایید'
                         ;
      RAISERROR (@MessageShow, 
               --N'خطا 4 - این شماره پرونده فاقد اعتبار عضویت باشگاه می باشد. لطفا اول جهت تمدید قرارداد اقدام کنید سپس حضوری ثبت کنید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
   END;
   
   -- بررسی کردن گزینه بلوکه کردن
   IF EXISTS(
      SELECT *
        FROM dbo.Fighter f, dbo.Member_Ship m
       WHERE f.FILE_NO = m.FIGH_FILE_NO
         AND f.MBFZ_RWNO_DNRM = m.RWNO
         AND m.RECT_CODE = '004'
         AND f.FILE_NO = @Figh_File_No
         AND CAST(GETDATE() AS DATE) BETWEEN m.STRT_DATE AND m.END_DATE
   )
   BEGIN
      SELECT @StrtDateStr = dbo.GET_MTOS_U(m.STRT_DATE)
            ,@EndDate = dbo.GET_MTOS_U(m.END_DATE)
        FROM dbo.Fighter f, dbo.Member_Ship m
       WHERE f.FILE_NO = m.FIGH_FILE_NO
         AND f.MBFZ_RWNO_DNRM = m.RWNO
         AND m.RECT_CODE = '004'
         AND f.FILE_NO = @Figh_File_No
         AND CAST(GETDATE() AS DATE) BETWEEN m.STRT_DATE AND m.END_DATE;
         
      SET @MessageShow = N'هشدار!!!' + CHAR(10) + 
                         @SexDesc + N' ' + @NameDnrm + CHAR(10) +
                         N'تاریخ شروع ' + @StrtDateStr + N' تاریخ پایان ' + @EndDate + CHAR(10) +
                         N' وضعیت خود را بلوکه کرده و نمی تواند وارد باشگاه شود.';
      RAISERROR (@MessageShow, 
               --N'خطا 4 - این شماره پرونده فاقد اعتبار عضویت باشگاه می باشد. لطفا اول جهت تمدید قرارداد اقدام کنید سپس حضوری ثبت کنید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
   END 
              
   -- کردن زمان شروع و پایان کار هنرجو
   IF EXISTS(
      SELECT *
        FROM Fighter F, Member_Ship M
       WHERE M.FIGH_FILE_NO = @Figh_File_No
         AND M.FIGH_FILE_NO = F.FILE_NO
         AND F.FGPB_TYPE_DNRM IN ( '001', '005', '006' )
         AND M.TYPE = '001'
         AND M.RECT_CODE = '004'
         AND M.RWNO = @MbspRwno--F.MBSP_RWNO_DNRM
         AND CAST(M.END_DATE AS DATE) < CAST(/*GETDATE()*/@Attn_Date AS DATE)
   )
   BEGIN
      SET @MessageShow = N'هشدار!!!' + CHAR(10) + 
                         @SexDesc + N' ' + @NameDnrm + CHAR(10) +
                         N'تاریخ شروع ' + @StrtDateStr + N' تاریخ پایان ' + @EndDate + CHAR(10) +
                         N' تعداد جلسات حضوری ' + CAST(@SumAttnMontDnrm AS VARCHAR(5)) + CHAR(10) +
                         N' تاریخ عضویت شما به پایان رسیده.' + CHAR(10) +
                         N'لطفا جهت تمدید عضویت اقدام فرمایید'
                         ;
      RAISERROR (@MessageShow, 
               --N'خطا 4 - این شماره پرونده فاقد اعتبار عضویت باشگاه می باشد. لطفا اول جهت تمدید قرارداد اقدام کنید سپس حضوری ثبت کنید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
   END
   
   -- چک کردن تعداد جلسات هنرجویان
   IF EXISTS(
      SELECT *
        FROM Fighter F, Member_Ship M
       WHERE M.FIGH_FILE_NO = @Figh_File_No
         AND M.FIGH_FILE_NO = F.FILE_NO
         AND M.TYPE IN ( '001', '005', '006' )
         AND M.RECT_CODE = '004'
         AND M.RWNO = @MbspRwno--F.MBSP_RWNO_DNRM
         --AND CAST(M.END_DATE AS DATE) >= CAST(GETDATE() AS DATE)
         AND ISNULL(m.NUMB_OF_ATTN_MONT, 0) > 0
         AND ISNULL(M.NUMB_OF_ATTN_MONT, 0) <= ISNULL(M.SUM_ATTN_MONT_DNRM, 0) /*- 1*/
         AND NOT EXISTS(
            SELECT * 
              FROM dbo.Attendance
             WHERE FIGH_FILE_NO = @Figh_File_No
               AND MBSP_RWNO_DNRM = m.RWNO
               AND MBSP_RECT_CODE_DNRM = m.RECT_CODE
               AND EXIT_TIME IS NULL
         )
   )
   BEGIN
      SET @MessageShow = N'هشدار!!!' + CHAR(10) + 
                         @SexDesc + N' ' + @NameDnrm + CHAR(10) + 
                         N'تاریخ شروع ' + @StrtDateStr + N' تاریخ پایان ' + @EndDate + CHAR(10) +
                         N' تعداد کل جلسات ' + CAST(@NumbOfAttnMont AS VARCHAR(5)) + N' تعداد جلسات حضوری ' + CAST(@SumAttnMontDnrm AS VARCHAR(5)) + CHAR(10) +
                         N' تعداد جلسات شما به پایان رسیده.' + CHAR(10) +
                         N'لطفا جهت تمدید عضویت اقدام فرمایید'
                         ;
      RAISERROR (@MessageShow, 
               --N'خطا 4 - این شماره پرونده فاقد اعتبار عضویت باشگاه می باشد. لطفا اول جهت تمدید قرارداد اقدام کنید سپس حضوری ثبت کنید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
               
      --RAISERROR ( N'خطا 5 - تعداد جلسات این شماره پرونده به اتمام رسیده است. لطفا اول جهت تمدید قرارداد اقدام کنید سپس حضوری ثبت کنید', -- Message text.
      --         16, -- Severity.
      --         1 -- State.
      --         );
   END
   
   -- حضوری در هفته   
   
   /*IF EXISTS(
      SELECT *
        FROM Fighter F, Member_Ship M
       WHERE M.FIGH_FILE_NO = @Figh_File_No
         AND M.FIGH_FILE_NO = F.FILE_NO
         AND M.TYPE IN ( '001', '005', '006' )
         AND M.RECT_CODE = '004'
         AND M.RWNO = F.MBSP_RWNO_DNRM
         AND ISNULL(m.NUMB_OF_ATTN_WEEK, 0) > 0
         AND ISNULL(M.NUMB_OF_ATTN_WEEK, 0) <= ISNULL(M.SUM_ATTN_WEEK_DNRM, 0)
   )
   BEGIN
      RAISERROR ( N'خطا - تعداد جلسات حضوری در هفته این شماره پرونده به اتمام رسیده است. شما دیگر اجازه ورود در این هفته را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
   END*/
   
   -- آیا امروز دوبار وارد باشگاه نمیشود.
   IF (
      EXISTS(
         SELECT *
           FROM Settings S, Fighter F
          WHERE S.CLUB_CODE = @Club_Code
            AND F.FILE_NO = @Figh_File_No
            AND F.FGPB_TYPE_DNRM IN ('001', '005', '006')
            AND S.MORE_ATTN_SESN = '002' -- تک جلسه در روز
      ) AND
      EXISTS ( 
         SELECT *
           FROM dbo.Fighter F, dbo.Member_Ship M, dbo.Attendance A
          WHERE F.FILE_NO = M.FIGH_FILE_NO
            --AND F.MBSP_RWNO_DNRM = M.RWNO
            AND m.RWNO = @MbspRwno
            AND M.RECT_CODE = '004'
            AND M.FIGH_FILE_NO = A.FIGH_FILE_NO
            AND M.RWNO = A.MBSP_RWNO_DNRM
            AND M.RECT_CODE = A.MBSP_RECT_CODE_DNRM    
            AND CAST(A.ATTN_DATE AS DATE) = CAST(/*GETDATE()*/@Attn_Date AS DATE)
            AND A.EXIT_TIME IS NOT NULL
            AND F.FILE_NO = @Figh_File_No
      )
   )
   BEGIN
      SET @MessageShow = N'هشدار!!!' + CHAR(10) + 
                         @SexDesc + N' ' + @NameDnrm + CHAR(10) + 
                         N' طبق مقررات باشگاه شما در طول روز فقط اجازه یک بار حضور در باشگاه را دارید' 
                         ;
      RAISERROR (@MessageShow, 
               --N'خطا 4 - این شماره پرونده فاقد اعتبار عضویت باشگاه می باشد. لطفا اول جهت تمدید قرارداد اقدام کنید سپس حضوری ثبت کنید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      --RAISERROR(N'خطا 6 - شما هنرجوی عزیز در طول روز فقط یک جلسه با مربی قادر به تمرین می باشید', 16, 1);
      RETURN;
   END
   
   -- بررسی حضوری در روز مورد مقرر
   -- 1395/06/18 * اگر حضوری بدون شرط و حضوری با مربی دیگر باشه چک نمی کنیم
   IF @Attn_TYPE NOT IN ('004', '005') AND
     EXISTS(
      SELECT *
        FROM dbo.Member_Ship mb, dbo.Fighter_Public f, dbo.Club_Method cm, dbo.Club_Method_Weekday cmw
       WHERE f.FIGH_FILE_NO = @Figh_File_No       
         AND mb.FIGH_FILE_NO = f.FIGH_FILE_NO
         AND mb.FGPB_RWNO_DNRM = f.RWNO
         AND mb.FGPB_RECT_CODE_DNRM = f.RECT_CODE         
         AND mb.RWNO = @MbspRwno
         AND F.[TYPE] IN ('001', '005', '006')
         AND F.CBMT_CODE = Cm.CODE
         AND Cm.CODE = cmw.CBMT_CODE
         AND NOT EXISTS(
            SELECT *
              FROM dbo.Attendance a
             WHERE a.FIGH_FILE_NO = f.FIGH_FILE_NO
               --AND f.MBSP_RWNO_DNRM = a.MBSP_RWNO_DNRM
               AND a.MBSP_RWNO_DNRM = @MbspRwno
               AND a.MBSP_RECT_CODE_DNRM = '004'
               AND a.ENTR_TIME IS NULL
         )
         AND ( 
               (CAST(cmw.WEEK_DAY AS SMALLINT) = DATEPART(DW, /*GETDATE()*/@Attn_Date) AND cmw.STAT = '001' /* مجاز نباشد */) OR 
               (cm.CBMT_TIME_STAT = '002' /* اگر ساعت و زمان برای کلاس فعال باشد */  AND CAST(GETDATE() AS TIME(0)) < CAST(cm.STRT_TIME AS TIME(0)) /* NOT BETWEEN CAST(cm.STRT_TIME AS TIME(0)) AND CAST(cm.END_TIME AS TIME(0)) */)               
             )
         
   )
   BEGIN
      SET @MessageShow = N'هشدار!!!' + CHAR(10) + 
                         @SexDesc + N' ' + @NameDnrm + CHAR(10) +
                         N' برنامه کلاسی شما در امروز یا این ساعت تعریف نشده است.' + CHAR(10) +
                         N'اگر مایل به جابه جا کردن ساعت کلاسی هستید با مدیریت باشگاه هماهنگی فرمایید'
                         ;
      RAISERROR (@MessageShow, 
               --N'خطا 4 - این شماره پرونده فاقد اعتبار عضویت باشگاه می باشد. لطفا اول جهت تمدید قرارداد اقدام کنید سپس حضوری ثبت کنید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      --RAISERROR(N'خطا 7 - شما هنرجوی عزیز برنامه کلاسی شما در امروز تعریف نشده است', 16, 1);
      RETURN;
   END
   
   
   
   -- 1395/07/21 ** بررسی میزان بدهی هنرجو برای حضور درون باشگاه
   IF @Attn_Type NOT IN ('005')
   BEGIN
      DECLARE @DebtDnrm BIGINT
		       ,@DebtChckStat VARCHAR(3);
      SELECT @DebtDnrm = DEBT_DNRM
			   ,@DebtChckStat = s.DEBT_CHCK_STAT
        FROM dbo.Fighter f, dbo.Settings s
       WHERE f.FILE_NO = @Figh_File_No
         AND f.CLUB_CODE_DNRM = s.CLUB_CODE;
      
      -- اگر هنرجو بدهی داشته باشد
      IF @DebtDnrm > 0 AND @DebtChckStat = '002'
      BEGIN
         DECLARE @StrtDate DATE
                ,@NumbOfMontDnrm INT
                ,@NumbOfDayDnrm INT
                ,@TempMbspRwno SMALLINT
                ,@TotlAttn INT
                ,@Rqid BIGINT
                ,@Amnt BIGINT;
         
         SELECT TOP 1 
               @TempMbspRwno = M.RWNO,
               @StrtDate = M.STRT_DATE, 
               @Rqid = R.RQID, 
               @NumbOfMontDnrm = M.NUMB_OF_MONT_DNRM, 
               @NumbOfDayDnrm = M.NUMB_OF_DAYS_DNRM,
               @TotlAttn = M.NUMB_OF_ATTN_MONT
           FROM dbo.Fighter F, dbo.Member_Ship M, dbo.Request R
          WHERE F.FILE_NO = @Figh_File_No
            AND F.FILE_NO = M.FIGH_FILE_NO
            --AND F.MBSP_RWNO_DNRM = M.RWNO
            AND m.RWNO = @MbspRwno
            AND M.RECT_CODE = '004'
            AND R.RQID = M.RQRO_RQST_RQID
            AND R.RQTP_CODE = '009' -- درخواست تمدید باشگاه
            AND R.RQTT_CODE = '001' -- متقاضی هنرجو می باشد
            AND R.RQST_STAT = '002' -- درخواست پایانی شده باشد
          ORDER BY R.SAVE_DATE DESC;
         
         IF @MbspRwno IS NULL OR @MbspRwno = 0
            SELECT TOP 1 
                  @TempMbspRwno = 1,
                  @StrtDate = M.STRT_DATE, 
                  @Rqid = R.RQID, 
                  @NumbOfMontDnrm = M.NUMB_OF_MONT_DNRM, 
                  @NumbOfDayDnrm = M.NUMB_OF_DAYS_DNRM,
                  @TotlAttn = M.NUMB_OF_ATTN_MONT
              FROM dbo.Fighter F, dbo.Member_Ship M, dbo.Request R, Request_Row Rr
             WHERE F.FILE_NO = @Figh_File_No
               AND F.FILE_NO = M.FIGH_FILE_NO
               AND R.RQID = Rr.RQST_RQID
               AND Rr.FIGH_FILE_NO = F.FILE_NO
               AND M.RWNO = 1 -- اولین رکورد تمدید باشگاه
               AND M.RECT_CODE = '004'
               AND R.RQTP_CODE = '001' -- درخواست تمدید باشگاه
               AND R.RQTT_CODE = '001' -- متقاضی هنرجو می باشد
               AND R.RQST_STAT = '002' -- درخواست پایانی شده باشد
             ORDER BY R.SAVE_DATE DESC;
         
         -- اگر تاریخ حضوری بیشتر تاریخ شروع جلسه هنرجو باشد
         IF DATEDIFF(DAY, @StrtDate , GETDATE()) > 0
         BEGIN
            SELECT @Amnt = SUM(SUM_EXPN_PRIC + SUM_EXPN_EXTR_PRCT)
              FROM dbo.Payment
             WHERE RQST_RQID = @Rqid
             GROUP BY RQST_RQID;
            
            -- آیا بدهی هنرجو بیش از حد مجاز می باشد
            IF @Amnt - @DebtDnrm <= 0 
            BEGIN
               SET @MessageShow = N'هشدار!!!' + CHAR(10) + 
                                  @SexDesc + N' ' + @NameDnrm + CHAR(10) + 
                                  N'تاریخ شروع ' + @StrtDateStr + N' تاریخ پایان ' + @EndDate + CHAR(10) +
                                  --N' تعداد کل جلسات ' + @NumbOfAttnMont + N' تعداد جلسات حضوری ' + @SumAttnMontDnrm + CHAR(10) +
                                  N' میزان بدهی شما بیش از حد مجاز می باشد.' + CHAR(10) +
                                  N'لطفا جهت تسویه حساب اقدام فرمایید'
                                  ;
               RAISERROR (@MessageShow, 
                        --N'خطا 4 - این شماره پرونده فاقد اعتبار عضویت باشگاه می باشد. لطفا اول جهت تمدید قرارداد اقدام کنید سپس حضوری ثبت کنید', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               --RAISERROR (N'خطا 8 - میزان بدهی هنرجو بیش از حد مجاز می باشد. لطفا جهت تسویه حساب هنرجو اقدام فرمایید', 16, 1);            
               RETURN;
            END -- آیا بدهی هنرجو بیش از حد مجاز می باشد            
            
            DECLARE @AttnPric INT;
           
            -- اگر تعداد جلسات هنرجو مشخص باشد
            IF @TotlAttn > 0
            BEGIN
               SELECT @AttnPric = ROUND(@Amnt / @TotlAttn, -3);               
            END -- اگر تعداد جلسات هنرجو مشخص باشد
            -- اگر تعداد جلسات هنرجو مشخص نباشد از تعداد روزهای بدست آمده بررسی هزینه هر جلسه را جلو می بریم
            ELSE
            BEGIN
               SELECT @AttnPric = ROUND(@Amnt / (@NumbOfDayDnrm - 4 * @NumbOfMontDnrm), -3);            
            END
            IF ((@Amnt - @DebtDnrm) / @AttnPric) <=
               (SELECT COUNT(*) 
                  FROM dbo.Attendance 
                 WHERE FIGH_FILE_NO = @Figh_File_No 
                   AND MBSP_RECT_CODE_DNRM = '004' 
                   AND MBSP_RWNO_DNRM >= @TempMbspRwno 
                   AND EXIT_TIME IS NOT NULL
                   AND ATTN_STAT = '002') + 1
            BEGIN
               SET @MessageShow = N'هشدار!!!' + CHAR(10) + 
                                  @SexDesc + N' ' + @NameDnrm + CHAR(10) +
                                  N'تاریخ شروع ' + @StrtDateStr + N' تاریخ پایان ' + @EndDate + CHAR(10) +
                                  N' تعداد کل جلسات ' + CAST(@NumbOfAttnMont AS VARCHAR(5)) + N' تعداد جلسات حضوری ' + CAST(@SumAttnMontDnrm AS VARCHAR(5)) + CHAR(10) +
                                  N' میزان بدهی هنرجو بیش از حد تعداد جلسات حضوری می باشد.' + CHAR(10) +
                                  N'لطفا جهت تسویه حساب اقدام فرمایید'
                                  ;
               RAISERROR (@MessageShow, 
                        --N'خطا 4 - این شماره پرونده فاقد اعتبار عضویت باشگاه می باشد. لطفا اول جهت تمدید قرارداد اقدام کنید سپس حضوری ثبت کنید', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               --RAISERROR (N'خطا 9 - میزان بدهی هنرجو بیش از حد تعداد جلسات حضوری می باشد. لطفا جهت تسویه حساب بقیه جلسات هنرجو اقدام فرمایید', 16, 1);            
               RETURN;
            END
         END -- اگر تاریخ حضوری بیشتر تاریخ شروع جلسه هنرجو باشد
      END -- اگر هنرجو بدهی داشته باشد
   END -- 1395/07/21 ** بررسی میزان بدهی هنرجو برای حضور درون باشگاه
   
   
   L$ATTN:
   DECLARE @AttnCode BIGINT
          ,@AttnDate DATE;
          
   SELECT @AttnCode = CODE
         ,@AttnDate = ATTN_DATE
     FROM Attendance
    WHERE FIGH_FILE_NO = @Figh_File_No
      AND CLUB_CODE = @Club_Code
      AND MBSP_RWNO_DNRM = @MbspRwno
      AND ENTR_TIME IS NOT NULL
      AND EXIT_TIME IS NULL;
   
   DECLARE @ExitTime TIME(0);
   SET @ExitTime = NULL;
    -- ثبت جلسه برای هنرجویان جلسه ای تک روزه
   IF EXISTS(
      SELECT *
        FROM Fighter F, Member_Ship M
       WHERE F.FILE_NO = @Figh_File_No
         AND F.FILE_NO = M.FIGH_FILE_NO
         --AND F.MBSP_RWNO_DNRM = M.RWNO
         AND m.RWNO = @MbspRwno
         AND M.RECT_CODE = '004'
         AND F.FGPB_TYPE_DNRM = '008'
         AND F.CONF_STAT = '002'
         AND DATEDIFF(DAY, M.STRT_DATE, M.END_DATE) = 0
   )
   BEGIN
      SET @ExitTime = DATEADD(MINUTE, 90,GETDATE());
   END
   
   -- 1395/06/18 * اگر هنرجو غیبت داشته باشد
   IF @Attn_Type = '002'
      SET @ExitTime = GETDATE();
   
   -- برای مشتریان جلسات ترکیبی
   IF @CochFileNo = 0 OR ISNULL(@CochFileNo, 0) = 0
   BEGIN      
      DECLARE @SesnSnid BIGINT
             ,@MtodCode BIGINT
             ,@CtgyCode BIGINT;
      IF @Type = '009'
      BEGIN
         SELECT TOP 1 @CochFileNo = COCH_FILE_NO_DNRM, @SesnSnid = SESN_SNID, @MtodCode = MTOD_CODE_DNRM, @CtgyCode = CTGY_CODE_DNRM
           FROM dbo.Session_Meeting
          WHERE MBSP_FIGH_FILE_NO = @Figh_File_No
       ORDER BY CRET_DATE DESC;       
      END
   END
   
   -- پایان دسترسی    
   -- 1396/07/16 * اگر عضو باشگاه به همراه خود بخواهد همراهی به باشگاه بیاورد
   IF @AttnCode IS NULL OR @Attn_TYPE IN ( '007' , '008' )
      INSERT INTO Attendance (CLUB_CODE, FIGH_FILE_NO, ATTN_DATE, CODE, EXIT_TIME, COCH_FILE_NO, ATTN_TYPE, SESN_SNID_DNRM, MTOD_CODE_DNRM, CTGY_CODE_DNRM, MBSP_RWNO_DNRM, MBSP_RECT_CODE_DNRM)
      VALUES (@Club_Code, @Figh_File_No, @Attn_Date, dbo.GNRT_NVID_U(), @ExitTime, @CochFileNo, @Attn_TYPE, @SesnSnid, @MtodCode, @CtgyCode, @MbspRwno, '004');
   ELSE
   BEGIN
      -- 1396/08/08 * برای محاسبه ساعت خروج واقعی
      DECLARE @ClasTime INT, @EntrTime TIME(0);
      SELECT TOP 1 @ClasTime = cm.CLAS_TIME
            ,@EntrTime = a.ENTR_TIME
        FROM dbo.Attendance a, dbo.Club_Method cm
       WHERE a.CLUB_CODE = cm.CLUB_CODE
         AND a.COCH_FILE_NO = cm.COCH_FILE_NO
         AND a.MTOD_CODE_DNRM = cm.MTOD_CODE
         AND a.ENTR_TIME BETWEEN cm.STRT_TIME AND cm.END_TIME;
      
      
      UPDATE Attendance
         SET EXIT_TIME = CASE 
                           WHEN CAST(GETDATE() AS TIME(0)) < ENTR_TIME THEN 
                              CAST(DATEADD(MINUTE, ISNULL(@ClasTime, 90),ENTR_TIME) AS TIME(0)) 
                           ELSE CAST(GETDATE() AS TIME(0)) 
                         END
       WHERE CODE = @AttnCode;      
      
      
      -- پس گرفتن کلید کمد از کاربر اگر سامانه کمد فعال باشد و به صورت اتوماتیک انجام شود
      --IF EXISTS(SELECT * FROM Settings WHERE DRES_STAT = '002' AND DRES_AUTO = '002' AND CLUB_CODE = @Club_Code)
      --BEGIN
      --   DECLARE @DresCode BIGINT
      --          ,@ClubCode BIGINT;
         
      --   SELECT @DresCode = Da.DRES_CODE
      --     FROM Dresser_Attendance Da
      --    WHERE Da.ATTN_CODE = @AttnCode
      --      AND Da.Lend_Time IS NOT NULL
      --      AND Da.Tkbk_Time IS NULL
      --   IF @DresCode IS NOT NULL
      --      UPDATE Dresser_Attendance
      --         SET TKBK_TIME = CAST(GETDATE() AS TIME(0))
      --       WHERE DRES_CODE = @DresCode
      --         AND ATTN_CODE = @AttnCode
      --         AND LEND_TIME IS NOT NULL
      --         AND TKBK_TIME IS NULL;        
      --END
      
      IF @AttnDate != CAST(/*GETDATE()*/@Attn_Date AS DATE) AND @Attn_Type != '003' -- خروج بدون حضور مجدد
      BEGIN
         SELECT @AttnCode = NULL, @AttnDate = NULL;
         GOTO L$ATTN;
      END
   END
   
   COMMIT TRAN INS_ATTN_P_T
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN INS_ATTN_P_T;
   END CATCH   
END
GO
