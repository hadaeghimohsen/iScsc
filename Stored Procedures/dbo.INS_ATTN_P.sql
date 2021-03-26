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
	@Mbsp_Rwno SMALLINT,
	@Attn_Sys_Type VARCHAR(3) = '001', -- نوع ثبت حضوری * دستی * سیستمی
	@Attn_Ignr_Stat VARCHAR(3) = '001'
AS
BEGIN
   BEGIN TRY
   BEGIN TRAN INS_ATTN_P_T
	/*DECLARE @AP BIT
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
   END*/
   
   DECLARE @HostName NVARCHAR(128)
          ,@ComaCode BIGINT;   
   
   IF ISNULL(@Mbsp_Rwno, 0) = 0
   BEGIN
      IF EXISTS(SELECT * FROM dbo.Fighter WHERE FILE_NO = @Figh_File_No AND FGPB_TYPE_DNRM = '003' AND CONF_STAT = '002')
      BEGIN
         SELECT @Mbsp_Rwno = MAX(ms.RWNO)
           FROM dbo.Member_Ship ms
          WHERE ms.FIGH_FILE_NO = @Figh_File_No
            AND ms.VALD_TYPE = '002'
            AND ms.RECT_CODE = '004'
            AND GETDATE() BETWEEN ms.STRT_DATE AND ms.END_DATE;
      END
      ELSE   
      BEGIN         
         RAISERROR ( N'اعضای گرامی، دوره ای برای شما وجود ندارد یا دوره شما به اتمام رسیده', -- Message text.
                  16, -- Severity.
                  1 -- State.
                  );
         RETURN;
      END;
   END
   
   IF EXISTS(SELECT * FROM dbo.Member_Ship WHERE FIGH_FILE_NO = @Figh_File_No AND RWNO = @Mbsp_Rwno AND RECT_CODE = '004' AND VALD_TYPE = '001')
   BEGIN
      RAISERROR ( N'دوره مورد نظر شما حذف شده است', -- Message text.
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
      /*SELECT @CochFileNo = COCH_FILE_NO_DNRM, 
             @Mbsp_Rwno   = ISNULL(@Mbsp_Rwno, MBSP_RWNO_DNRM)
        FROM dbo.Fighter
       WHERE FILE_NO = @Figh_File_No
         AND FGPB_TYPE_DNRM NOT IN ('002', '003');*/
      SELECT @CochFileNo = fp.COCH_FILE_NO
        FROM dbo.Member_Ship m, dbo.Fighter_Public fp
       WHERE m.FIGH_FILE_NO = fp.FIGH_FILE_NO
         AND m.FGPB_RWNO_DNRM = fp.RWNO
         AND m.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
         AND m.RWNO = @Mbsp_Rwno
         AND m.RECT_CODE = '004'
         AND m.FIGH_FILE_NO = @Figh_File_No;
   END
   
   -- اگر خروج دستی ثبت شده باشد بدون هیچ گونه بررسی خروج زده شود
   IF @Attn_TYPE IN ( '003' )
      GOTO L$ATTN;
   
   DECLARE @NameDnrm NVARCHAR(500)
          ,@EndDate VARCHAR(10)
          ,@SexDesc NVARCHAR(10)
          ,@GlobCode NVARCHAR(50)
          ,@MessageShow NVARCHAR(MAX)
          ,@StrtDateStr VARCHAR(10)          
          --,@EndDate DATE
          ,@NumbOfAttnMont INT
          ,@SumAttnMontDnrm INT;
   
   SELECT @NameDnrm = NAME_DNRM
         ,@EndDate = dbo.GET_MTOS_U(MBSP_END_DATE)
         ,@SexDesc = sxdc.DOMN_DESC
         ,@GlobCode = f.GLOB_CODE_DNRM
         ,@StrtDateStr = dbo.GET_MTOS_U(MBSP_STRT_DATE)
         ,@NumbOfAttnMont = M.NUMB_OF_ATTN_MONT
         ,@SumAttnMontDnrm = M.SUM_ATTN_MONT_DNRM
         --,@EndDate = MBSP_END_DATE
     FROM dbo.Fighter F, dbo.D$SXDC sxdc, dbo.Member_Ship M
    WHERE F.FILE_NO = @Figh_File_No
      AND F.FILE_NO = M.FIGH_FILE_NO
      --AND F.MBSP_RWNO_DNRM = M.RWNO
      AND m.RWNO = @Mbsp_Rwno
      AND M.RECT_CODE = '004'
      AND m.VALD_TYPE = '002'
      AND F.SEX_TYPE_DNRM = sxdc.VALU;
   
   -- پایان مهلت بدهی هنرجو
   
   IF @Attn_Ignr_Stat = '001'   
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
   IF @Attn_Ignr_Stat = '001'
      IF EXISTS(
         SELECT *
           FROM dbo.Fighter f, dbo.Member_Ship m
          WHERE f.FILE_NO = m.FIGH_FILE_NO
            AND f.MBFZ_RWNO_DNRM = m.RWNO
            AND m.RECT_CODE = '004'
            AND f.FILE_NO = @Figh_File_No
            AND m.VALD_TYPE = '002'
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
            AND m.VALD_TYPE = '002'
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
   
   -- 1396/11/23 * بررسی اینکه آیا مشترکین اشتراکی جلسه باقیمانده دارند یا خیر
   IF EXISTS(
      SELECT *
        FROM dbo.Settings
       WHERE CLUB_CODE = @Club_Code
         AND SHAR_MBSP_STAT = '002'
   )
   BEGIN
      IF @GlobCode IS NOT NULL AND @GlobCode != '' AND LEN(@GlobCode) > 2 AND 
         EXISTS(
			SELECT *
			  FROM dbo.Member_Ship ms, dbo.Fighter_Public fp, dbo.Method m
			 WHERE ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
			   AND ms.FGPB_RWNO_DNRM = fp.RWNO
			   AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
			   AND fp.MTOD_CODE = m.CODE
			   AND m.CHCK_ATTN_ALRM = '002'
			   AND ms.FIGH_FILE_NO = @Figh_File_No
			   AND ms.RWNO = @Mbsp_Rwno
			   AND ms.RECT_CODE = '004'
			   AND ms.VALD_TYPE = '002'
         )
      BEGIN
         DECLARE @SumAttnCont INT;
         SELECT @SumAttnCont = COUNT(*)           
           FROM dbo.Attendance a, dbo.Method m
          WHERE GLOB_CODE_DNRM = @GlobCode
            AND a.MTOD_CODE_DNRM = m.CODE
            AND m.CHCK_ATTN_ALRM = '002'
            AND a.ATTN_STAT = '002'
            AND SUBSTRING(dbo.GET_MTOS_U(ATTN_DATE), 1, 7) = SUBSTRING(dbo.GET_MTOS_U(@Attn_Date), 1, 7);
         
         IF @SumAttnCont >= @NumbOfAttnMont
            GOTO L$AttnEror_EndOfCycl;
      END
   END
   
   -- کردن زمان شروع و پایان کار هنرجو
   IF @Attn_Ignr_Stat = '001'
      IF EXISTS(
         SELECT *
           FROM Fighter F, Member_Ship M
          WHERE M.FIGH_FILE_NO = @Figh_File_No
            AND M.FIGH_FILE_NO = F.FILE_NO
            AND F.FGPB_TYPE_DNRM IN ( '001', '005', '006' )
            AND M.TYPE = '001'
            AND M.RECT_CODE = '004'
            AND m.VALD_TYPE = '002'
            AND M.RWNO = @Mbsp_Rwno--F.MBSP_RWNO_DNRM
            AND CAST(m.STRT_DATE as DATE) <= CAST(GETDATE() AS DATE)
            AND CAST(M.END_DATE AS DATE) < CAST(/*GETDATE()*/@Attn_Date AS DATE)
      )
      BEGIN
         L$AttnEror_EndOfCycl:
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
   IF @Attn_Ignr_Stat = '001'
      IF EXISTS(
         SELECT *
           FROM Fighter F, Member_Ship M
          WHERE M.FIGH_FILE_NO = @Figh_File_No
            AND M.FIGH_FILE_NO = F.FILE_NO
            AND M.TYPE IN ( '001', '005', '006' )
            AND M.RECT_CODE = '004'
            AND m.VALD_TYPE = '002'
            AND M.RWNO = @Mbsp_Rwno--F.MBSP_RWNO_DNRM
            --AND CAST(M.END_DATE AS DATE) >= CAST(GETDATE() AS DATE)
            AND CAST(m.STRT_DATE as DATE) <= CAST(GETDATE() AS DATE)
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
   IF @Attn_Ignr_Stat = '001'
      IF (
         EXISTS(
            SELECT *
              FROM Settings S, Fighter F
             WHERE S.CLUB_CODE = @Club_Code
               AND F.FILE_NO = @Figh_File_No
               AND F.FGPB_TYPE_DNRM IN ('001', '005', '006')
               AND S.MORE_ATTN_SESN = '002' -- تک جلسه در روز
         ) AND
         NOT EXISTS(
             SELECT *
               FROM dbo.Exception_Operation
              WHERE FIGH_FILE_NO = @Figh_File_No
                AND EXCP_TYPE = '001' -- Attendance
                AND STAT = '002'
         ) AND         
         EXISTS ( 
            SELECT *
              FROM dbo.Fighter F, dbo.Member_Ship M, dbo.Attendance A
             WHERE F.FILE_NO = M.FIGH_FILE_NO
               --AND F.MBSP_RWNO_DNRM = M.RWNO
               AND m.RWNO = @Mbsp_Rwno
               AND M.RECT_CODE = '004'
               AND m.VALD_TYPE = '002'
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
   IF @Attn_Ignr_Stat = '001'
      IF @Attn_TYPE NOT IN ('004', '005') AND
        EXISTS(
         SELECT *
           FROM dbo.Member_Ship mb, dbo.Fighter_Public f, dbo.Club_Method cm, dbo.Club_Method_Weekday cmw
          WHERE f.FIGH_FILE_NO = @Figh_File_No       
            AND mb.FIGH_FILE_NO = f.FIGH_FILE_NO
            AND mb.FGPB_RWNO_DNRM = f.RWNO
            AND mb.FGPB_RECT_CODE_DNRM = f.RECT_CODE         
            AND mb.RWNO = @Mbsp_Rwno
            AND mb.RECT_CODE = '004'
            AND F.[TYPE] IN ('001', '005', '006')
            AND F.CBMT_CODE = Cm.CODE
            AND Cm.CODE = cmw.CBMT_CODE
            AND mb.VALD_TYPE = '002'         
            AND NOT EXISTS(
               SELECT *
                 FROM dbo.Attendance a
                WHERE a.FIGH_FILE_NO = f.FIGH_FILE_NO
                  --AND f.MBSP_RWNO_DNRM = a.MBSP_RWNO_DNRM
                  AND a.MBSP_RWNO_DNRM = @Mbsp_Rwno
                  AND a.MBSP_RECT_CODE_DNRM = '004'
                  AND a.EXIT_TIME IS NULL
            )
            AND ( 
                  -- 1397/11/24 * به این گزینه نیازی نیست فقط ساعت کلاسی چک شود کافیه * (CAST(cmw.WEEK_DAY AS SMALLINT) = DATEPART(DW, /*GETDATE()*/@Attn_Date) AND cmw.STAT = '001' /* مجاز نباشد */) OR 
                  (cm.CBMT_TIME_STAT = '002' /* اگر ساعت و زمان برای کلاس فعال باشد */  AND (CAST(GETDATE() AS TIME(0)) < CAST(cm.STRT_TIME AS TIME(0)) OR CAST(GETDATE() AS TIME(0)) > CAST(cm.END_TIME AS TIME(0))) /* NOT BETWEEN CAST(cm.STRT_TIME AS TIME(0)) AND CAST(cm.END_TIME AS TIME(0)) */)               
                )
            
      )
      BEGIN
         DECLARE @MtodDesc NVARCHAR(250)
                ,@CtgyDesc NVARCHAR(250)
                ,@CochName NVARCHAR(250)
                ,@StrtTime NVARCHAR(5)
                ,@EndTime NVARCHAR(5)
                ,@Wkdy NVARCHAR(50);
         SELECT @MtodDesc = m.MTOD_DESC, 
                @CtgyDesc = cb.CTGY_DESC, 
                @CochName = c.NAME_DNRM, 
                @StrtTime = CAST(cm.STRT_TIME AS VARCHAR(5)), 
                @EndTime = CAST(cm.END_TIME AS VARCHAR(5)), 
                @Wkdy = (SELECT dw.DOMN_DESC + ',' FROM dbo.Club_Method_Weekday cmw, dbo.[D$WKDY] dw WHERE cm.CODE = cmw.CBMT_CODE AND dw.VALU = cmw.WEEK_DAY AND cmw.STAT = '002' ORDER BY cmw.WEEK_DAY FOR XML PATH(''))
           FROM dbo.Member_Ship mb, dbo.Fighter_Public f, dbo.Club_Method cm, dbo.Method m, dbo.Category_Belt cb, dbo.Fighter c
          WHERE f.FIGH_FILE_NO = @Figh_File_No
            AND mb.FIGH_FILE_NO = f.FIGH_FILE_NO
            AND mb.FGPB_RWNO_DNRM = f.RWNO
            AND mb.FGPB_RECT_CODE_DNRM = f.RECT_CODE         
            AND mb.RWNO = @Mbsp_Rwno
            AND mb.RECT_CODE = '004'
            AND F.[TYPE] IN ('001', '005', '006')
            AND F.CBMT_CODE = Cm.CODE
            AND mb.VALD_TYPE = '002'         
            AND f.MTOD_CODE = m.CODE
            AND f.CTGY_CODE = cb.CODE
            AND m.CODE = cb.MTOD_CODE
            AND cm.COCH_FILE_NO = c.FILE_NO;
      
         SET @MessageShow = N'هشدار!!!' + CHAR(10) + 
                            @SexDesc + N' ' + @NameDnrm + CHAR(10) +
                            N'برنامه کلاسی شما در رشته "' + @MtodDesc + N'" در رسته "' + @CtgyDesc + N'" با مربی "' + @CochName + N'" در ساعت [ ' + @StrtTime + N' ] تا [ ' + @EndTime + N' ] در ایام هفته "' + @Wkdy + N'" می باشد ';
                            --N' برنامه کلاسی شما در امروز یا این ساعت تعریف نشده است.' + CHAR(10) +
                            --N'اگر مایل به جابه جا کردن ساعت کلاسی هستید با مدیریت باشگاه هماهنگی فرمایید'
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
   IF @Attn_Ignr_Stat = '001'
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
               AND m.RWNO = @Mbsp_Rwno
               AND m.VALD_TYPE = '002'
               AND M.RECT_CODE = '004'
               AND R.RQID = M.RQRO_RQST_RQID
               AND R.RQTP_CODE = '009' -- درخواست تمدید باشگاه
               AND R.RQTT_CODE = '001' -- متقاضی هنرجو می باشد
               AND R.RQST_STAT = '002' -- درخواست پایانی شده باشد
             ORDER BY R.SAVE_DATE DESC;
            
            IF @Mbsp_Rwno IS NULL OR @Mbsp_Rwno = 0
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
                  AND m.VALD_TYPE = '002'
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
      AND MBSP_RWNO_DNRM = @Mbsp_Rwno
      AND ENTR_TIME IS NOT NULL
      AND EXIT_TIME IS NULL;
   
   DECLARE @ExitTime TIME(0);
   SET @ExitTime = NULL;
    -- ثبت جلسه برای هنرجویان جلسه ای تک روزه
   --IF EXISTS(
   --   SELECT *
   --     FROM Fighter F, Member_Ship M
   --    WHERE F.FILE_NO = @Figh_File_No
   --      AND F.FILE_NO = M.FIGH_FILE_NO
   --      --AND F.MBSP_RWNO_DNRM = M.RWNO
   --      AND m.RWNO = @Mbsp_Rwno
   --      AND M.RECT_CODE = '004'
   --      AND F.FGPB_TYPE_DNRM = '008'
   --      AND F.CONF_STAT = '002'
   --      AND m.VALD_TYPE = '002'
   --      AND DATEDIFF(DAY, M.STRT_DATE, M.END_DATE) = 0
   --)
   --BEGIN
   --   SET @ExitTime = DATEADD(MINUTE, 90,GETDATE());
   --END
   
   -- 1395/06/18 * اگر هنرجو غیبت داشته باشد
   IF @Attn_Type = '002'
      SET @ExitTime = GETDATE();
   
   -- برای مشتریان جلسات ترکیبی
   --IF @CochFileNo = 0 OR ISNULL(@CochFileNo, 0) = 0
   --BEGIN      
   --   DECLARE @SesnSnid BIGINT
   --          ,@MtodCode BIGINT
   --          ,@CtgyCode BIGINT;
   --   IF @Type = '009'
   --   BEGIN
   --      SELECT TOP 1 @CochFileNo = COCH_FILE_NO_DNRM, @SesnSnid = SESN_SNID, @MtodCode = MTOD_CODE_DNRM, @CtgyCode = CTGY_CODE_DNRM
   --        FROM dbo.Session_Meeting
   --       WHERE MBSP_FIGH_FILE_NO = @Figh_File_No
   --    ORDER BY CRET_DATE DESC;       
   --   END
   --END
   
   -- 1396/07/16 * اگر عضو باشگاه به همراه خود بخواهد همراهی به باشگاه بیاورد
   IF @AttnCode IS NULL OR @Attn_TYPE IN ( '007' , '008' )
   BEGIN
      -- 1397/12/04 * میزان محدودیت
      IF @Attn_TYPE IN ( '007' , '008' ) AND (
         SELECT COUNT(*)
           FROM dbo.Attendance a
          WHERE a.FIGH_FILE_NO = @Figh_File_No
            AND a.MBSP_RECT_CODE_DNRM = '004'
            AND a.MBSP_RWNO_DNRM = @Mbsp_Rwno
            AND a.ATTN_TYPE IN ('007', '008')
            AND a.ATTN_STAT = '002'
      ) >= (
         SELECT ISNULL(cb.GUST_NUMB, 0)
           FROM dbo.Member_Ship ms, dbo.Fighter_Public fp, dbo.Category_Belt cb
          WHERE ms.FIGH_FILE_NO = @Figh_File_No
            AND ms.RWNO = @Mbsp_Rwno
            AND ms.RECT_CODE = '004'
            AND ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
            AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
            AND ms.FGPB_RWNO_DNRM = fp.RWNO
            AND fp.CTGY_CODE = cb.CODE
            AND fp.MTOD_CODE = cb.MTOD_CODE
      )
      BEGIN
         RAISERROR ( N'تعداد ورود اعضا مهمان شما به اتمام رسیده است', 
                     16, -- Severity.
                     1 -- State.
                   );
         RETURN;
      END
      -- 1396/10/26 * گزینه مشخص شود که چه ورزشی می باشد      
      DECLARE @ChckAttnAlrm VARCHAR(3);
                   
      SELECT @ChckAttnAlrm = CHCK_ATTN_ALRM
        FROM dbo.Method m, dbo.Fighter_Public fp, dbo.Member_Ship ms
       WHERE m.CODE = fp.MTOD_CODE
         AND fp.RWNO = ms.FGPB_RWNO_DNRM
         AND fp.RECT_CODE = ms.FGPB_RECT_CODE_DNRM
         AND fp.FIGH_FILE_NO = ms.FIGH_FILE_NO
         AND ms.FIGH_FILE_NO = @Figh_File_No
         AND ms.RWNO = @Mbsp_Rwno
         AND ms.VALD_TYPE = '002';
      
      -- اگر برای ورزش نیازی به نظارت اپراتور وجود ندارد
      IF @ChckAttnAlrm = '002'
         SET @ExitTime = GETDATE();
      ELSE
         SET @ExitTime = NULL;
      
      SET @AttnCode = dbo.GNRT_NVID_U();
         
      INSERT INTO Attendance (CLUB_CODE, FIGH_FILE_NO, ATTN_DATE, CODE, EXIT_TIME, COCH_FILE_NO, ATTN_TYPE, SESN_SNID_DNRM, MTOD_CODE_DNRM, CTGY_CODE_DNRM, MBSP_RWNO_DNRM, MBSP_RECT_CODE_DNRM, ATTN_SYS_TYPE, SEND_MESG_STAT)
      VALUES (@Club_Code, @Figh_File_No, @Attn_Date, /*dbo.GNRT_NVID_U()*/ @AttnCode, @ExitTime, @CochFileNo, @Attn_TYPE, /*@SesnSnid*/NULL, /*@MtodCode*/NULL, /*@CtgyCode*/NULL, @Mbsp_Rwno, '004', @Attn_Sys_Type, '001');
      
      -- 1398/03/14 * اختصاص شماره کمد به مشتری
      -- البته اگر این گزینه کمد انلاین فعال باشه 
      -- 1396/01/09 * بدست آوردن کلاینت متصل به سرور
	   
	   IF EXISTS(SELECT * FROM dbo.Settings WHERE CLUB_CODE = @Club_Code AND DRES_AUTO = '002')
	   BEGIN
	      -- ابتدا بررسی میکنیم که چه کامیپوتری به کمد ها میخواد فرمان دهد
	      SELECT   
	          @HostName = s.host_name
           FROM sys.dm_exec_connections AS c  
           JOIN sys.dm_exec_sessions AS s  
             ON c.session_id = s.session_id  
          WHERE c.session_id = @@SPID; 
         
         SELECT @ComaCode = CODE
           FROM dbo.Computer_Action
          WHERE UPPER(COMP_NAME) LIKE UPPER(@HostName) + N'%';
         
         -- بررسی میکنیم که ایا سیستم مدیریت کمدی رو را انجام میدهد یا خیر
         IF EXISTS(SELECT * FROM dbo.Dresser WHERE COMA_CODE = @ComaCode AND REC_STAT = '002')
         BEGIN
            SELECT @AttnCode = MAX(CODE)
              FROM Attendance
             WHERE FIGH_FILE_NO = @Figh_File_No
               AND CLUB_CODE = @Club_Code
               AND MBSP_RWNO_DNRM = @Mbsp_Rwno
               AND ENTR_TIME IS NOT NULL
               AND EXIT_TIME IS NULL;
            
            -- اولین درخواست ثبت قفل کمدی
            EXEC dbo.INS_DART_P @AttnCode, @ComaCode;
            
            -- اگر درخواست قفل کمدی با موفقیت انجام شود
            IF EXISTS(SELECT * FROM dbo.Dresser_Attendance WHERE ATTN_CODE = @AttnCode)
            BEGIN                  
               -- ثبت شماره قفل کمدی
               UPDATE dbo.Attendance 
                  SET DERS_NUMB = (SELECT d.DRES_NUMB FROM dbo.Dresser_Attendance da, dbo.Dresser d WHERE da.ATTN_CODE = @AttnCode AND da.DRES_CODE = d.CODE)
                WHERE Code = @AttnCode;
            END
         END                
      END 
      
      -- 1398/4/11 * ثبت پیامک 
      DECLARE @CellPhon VARCHAR(11),
              @SexType VARCHAR(3),
              @FrstName NVARCHAR(250),
              @LastName NVARCHAR(250);
      
      SELECT @CellPhon = CELL_PHON_DNRM
            ,@SexType = SEX_TYPE_DNRM
            ,@FrstName = FRST_NAME_DNRM
            ,@LastName = LAST_NAME_DNRM
        FROM dbo.Fighter
       WHERE FILE_NO = @Figh_File_No
         AND FGPB_TYPE_DNRM = '001';
         
      IF @CellPhon IS NOT NULL AND LEN(@CellPhon) != 0 AND NOT EXISTS(SELECT * FROM dbo.Attendance WHERE CODE = @AttnCode AND SEND_MESG_STAT = '002')
      BEGIN
         DECLARE @MsgbStat VARCHAR(3)
                ,@MsgbText NVARCHAR(MAX)
                ,@ClubName NVARCHAR(250)
                ,@InsrCnamStat VARCHAR(3)
                ,@InsrFnamStat VARCHAR(3)
                ,@LineType VARCHAR(3);
                
         SELECT @MsgbStat = STAT
               ,@MsgbText = MSGB_TEXT
               ,@ClubName = CLUB_NAME
               ,@InsrCnamStat = INSR_CNAM_STAT
               ,@InsrFnamStat = INSR_FNAM_STAT
               ,@LineType = LINE_TYPE
           FROM dbo.Message_Broadcast
          WHERE MSGB_TYPE = '008';
         
         IF @MsgbStat = '002' 
         BEGIN
            IF @InsrFnamStat = '002'
               SET @MsgbText = (SELECT DOMN_DESC FROM dbo.[D$SXDC] WHERE VALU = @SexType) + N' ' + @FrstName + N' ' + @LastName + N' ' + @MsgbText;
            
            IF @InsrCnamStat = '002'
               SET @MsgbText = @MsgbText + N' ' + @ClubName;
               
            DECLARE @XMsg XML;
            SELECT @XMsg = (
               SELECT 5 AS '@subsys',
                      @LineType AS '@linetype',
                      (
                        SELECT @CellPhon AS '@phonnumb',
                               (
                                   SELECT '008' AS '@type' 
                                          ,@MsgbText
                                      FOR XML PATH('Message'), TYPE 
                               ) 
                           FOR XML PATH('Contact'), TYPE
                      )
                 FOR XML PATH('Contacts'), ROOT('Process')                            
            );
            EXEC dbo.MSG_SEND_P @X = @XMsg -- xml
            
            -- send sms successfully
            UPDATE dbo.Attendance 
               SET SEND_MESG_STAT = '002'
             WHERE CODE = @AttnCode;
         END;
      END;
      
      -- 1396/11/15 * ثبت پیامک تلگرام
      DECLARE @ChatId BIGINT
             --,@SexType VARCHAR(3)
             --,@FrstName NVARCHAR(250)
             --,@LastName NVARCHAR(250);
             
      SELECT @ChatId = CHAT_ID_DNRM
            ,@SexType = SEX_TYPE_DNRM
            ,@FrstName = FRST_NAME_DNRM
            ,@LastName = LAST_NAME_DNRM
        FROM dbo.Fighter
       WHERE FILE_NO = @Figh_File_No;       

      IF @ChatId IS NOT NULL
      BEGIN
         DECLARE @TelgStat VARCHAR(3)
                --,@MsgbStat VARCHAR(3)
                --,@MsgbText NVARCHAR(MAX)
                --,@ClubName NVARCHAR(250)
                --,@InsrCnamStat VARCHAR(3)
                --,@InsrFnamStat VARCHAR(3);
                
         SELECT @TelgStat = TELG_STAT
               ,@MsgbText = MSGB_TEXT
               ,@ClubName = CLUB_NAME
               ,@InsrCnamStat = INSR_CNAM_STAT
               ,@InsrFnamStat = INSR_FNAM_STAT
           FROM dbo.Message_Broadcast
          WHERE MSGB_TYPE = '008';
         
         IF @TelgStat = '002'
         BEGIN
            IF @InsrFnamStat = '002'
               SET @MsgbText = (SELECT DOMN_DESC FROM dbo.[D$SXDC] WHERE VALU = @SexType) + N' ' + @FrstName + N' ' + @LastName + N' ' + ISNULL(@MsgbText, N'')
            
            IF @InsrCnamStat = '002'
               SET @MsgbText = ISNULL(@MsgbText, N'') + N' ' + @ClubName;            
            
            SET @MsgbText += (
               SELECT CHAR(10) + N' شما در ساعت ' + CAST(ENTR_TIME AS VARCHAR(5)) + N' با مربی ' + c.NAME_DNRM + N' برای کلاس ' + m.MTOD_DESC + N' وارد باشگاه شده اید '
                 FROM dbo.Attendance a, dbo.Member_Ship ms, dbo.Fighter_Public fp, dbo.Method m, dbo.Fighter c
                WHERE a.CODE = @AttnCode
                  AND a.FIGH_FILE_NO = ms.FIGH_FILE_NO
                  AND ms.RWNO = @Mbsp_Rwno
                  AND ms.RECT_CODE = '004'
                  AND ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
                  AND ms.FGPB_RWNO_DNRM = fp.RWNO
                  AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
                  AND fp.MTOD_CODE = m.CODE
                  AND fp.COCH_FILE_NO = c.FILE_NO
            );   
            
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
      -- 1396/11/15 * ثبت پیامک تلگرام
   END
   ELSE
   BEGIN
      -- 1396/08/08 * برای محاسبه ساعت خروج واقعی
      DECLARE @ClasTime INT, @EntrTime TIME(0), @CbmtTimeStat VARCHAR(3);
      SELECT TOP 1 @ClasTime = cm.CLAS_TIME
            ,@EntrTime = a.ENTR_TIME
            ,@CbmtTimeStat = cm.CBMT_TIME_STAT
        FROM dbo.Attendance a, dbo.Club_Method cm
       WHERE a.CLUB_CODE = cm.CLUB_CODE
         AND a.COCH_FILE_NO = cm.COCH_FILE_NO
         AND a.MTOD_CODE_DNRM = cm.MTOD_CODE
         --AND a.ENTR_TIME BETWEEN cm.STRT_TIME AND cm.END_TIME
         AND a.CODE = @AttnCode;
      
      
      UPDATE Attendance
         SET EXIT_TIME = CASE 
                           WHEN CAST(GETDATE() AS TIME(0)) < ENTR_TIME THEN 
                              CAST(DATEADD(MINUTE, ISNULL(@ClasTime, 90),ENTR_TIME) AS TIME(0)) 
                           ELSE CAST(GETDATE() AS TIME(0)) 
                         END
       WHERE CODE = @AttnCode;            
      
      SELECT @ChatId = CHAT_ID_DNRM
            ,@SexType = SEX_TYPE_DNRM
            ,@FrstName = FRST_NAME_DNRM
            ,@LastName = LAST_NAME_DNRM
        FROM dbo.Fighter
       WHERE FILE_NO = @Figh_File_No;       

      IF @ChatId IS NOT NULL
      BEGIN                
         SELECT @TelgStat = TELG_STAT
               ,@MsgbText = MSGB_TEXT
               ,@ClubName = CLUB_NAME
               ,@InsrCnamStat = INSR_CNAM_STAT
               ,@InsrFnamStat = INSR_FNAM_STAT
           FROM dbo.Message_Broadcast
          WHERE MSGB_TYPE = '008';
         
         SET @MsgbText = '';
         
         IF @TelgStat = '002'
         BEGIN
            IF @InsrFnamStat = '002'
               SET @MsgbText = (SELECT DOMN_DESC FROM dbo.[D$SXDC] WHERE VALU = @SexType) + N' ' + @FrstName + N' ' + @LastName + N' ' + ISNULL(@MsgbText, N'')
            
            IF @InsrCnamStat = '002'
               SET @MsgbText = ISNULL(@MsgbText, N'') + N' ' + @ClubName;            
            
            SET @MsgbText += (
               SELECT CHAR(10) + N' شما در ساعت ' + CAST(a.EXIT_TIME AS VARCHAR(5)) + N' با مربی ' + c.NAME_DNRM + N' برای کلاس ' + m.MTOD_DESC + N' از باشگاه خارج شده اید '
                 FROM dbo.Attendance a, dbo.Member_Ship ms, dbo.Fighter_Public fp, dbo.Method m, dbo.Fighter c
                WHERE a.CODE = @AttnCode
                  AND a.FIGH_FILE_NO = ms.FIGH_FILE_NO
                  AND ms.RWNO = @Mbsp_Rwno
                  AND ms.RECT_CODE = '004'
                  AND ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
                  AND ms.FGPB_RWNO_DNRM = fp.RWNO
                  AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
                  AND fp.MTOD_CODE = m.CODE
                  AND fp.COCH_FILE_NO = c.FILE_NO
            );   
            
            IF EXISTS (SELECT name FROM sys.databases WHERE name = N'iRoboTech')
	         BEGIN
	            --DECLARE @RoboServFileNo BIGINT;
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
      -- 1396/11/15 * ثبت پیامک تلگرام      
      
      -- 1396/10/09 * بررسی اینکه آیا بیش از حد مجاز در کلاس بوده
      IF ISNULL(@CbmtTimeStat, '001') = '002' AND @ClasTime < ( SELECT DATEDIFF(MINUTE, ENTR_TIME, EXIT_TIME) FROM dbo.Attendance WHERE Code = @AttnCode)
      BEGIN
         DECLARE @TempAttnCode BIGINT = dbo.GNRT_NVID_U();
         
         -- 1398/03/17 * بررسی اینکه ایا جریمه دیر کرد از مشتری گرفته شود یا خیر
         -- ********************** Not Implement
         
         INSERT INTO Attendance (CLUB_CODE, FIGH_FILE_NO, ATTN_DATE, CODE, EXIT_TIME, COCH_FILE_NO, ATTN_TYPE, SESN_SNID_DNRM, MTOD_CODE_DNRM, CTGY_CODE_DNRM, MBSP_RWNO_DNRM, MBSP_RECT_CODE_DNRM, ATTN_DESC, ATTN_SYS_TYPE)
         VALUES (@Club_Code, @Figh_File_No, @Attn_Date, @TempAttnCode, /*DATEADD(MINUTE, @ClasTime, GETDATE())*/NULL, @CochFileNo, @Attn_TYPE, /*@SesnSnid*/NULL, /*@MtodCode*/NULL, /*@CtgyCode*/NULL, @Mbsp_Rwno, '004', N'کسر جلسه به دلیل تجاوز از ساعت حضور در باشگاه ' + ( SELECT CAST(DATEDIFF(MINUTE, ENTR_TIME, EXIT_TIME) AS VARCHAR(10)) FROM dbo.Attendance WHERE Code = @AttnCode), @Attn_Sys_Type );
         
         UPDATE dbo.Attendance
            SET EXIT_TIME = DATEADD(MINUTE, @ClasTime, GETDATE())
          WHERE CODE = @TempAttnCode;   
         
         -- 1396/11/15 * ثبت پیامک تلگرام      
         IF @ChatId IS NOT NULL
         BEGIN                
            SELECT @TelgStat = TELG_STAT
                  ,@MsgbText = MSGB_TEXT
                  ,@ClubName = CLUB_NAME
                  ,@InsrCnamStat = INSR_CNAM_STAT
                  ,@InsrFnamStat = INSR_FNAM_STAT
              FROM dbo.Message_Broadcast
             WHERE MSGB_TYPE = '008';
            
            SET @MsgbText = '';
            
            IF @TelgStat = '002'
            BEGIN
               IF @InsrFnamStat = '002'
                  SET @MsgbText = (SELECT DOMN_DESC FROM dbo.[D$SXDC] WHERE VALU = @SexType) + N' ' + @FrstName + N' ' + @LastName + N' ' + ISNULL(@MsgbText, N'')
               
               IF @InsrCnamStat = '002'
                  SET @MsgbText = ISNULL(@MsgbText, N'') + N' ' + @ClubName;            
               
               SET @MsgbText += (
                  SELECT CHAR(10) + N' شما بخاطر تجاوز از ساعت حضور در باشگاه' + N' با مربی ' + c.NAME_DNRM + N' برای کلاس ' + m.MTOD_DESC + N' از باشگاه خارج شده اید و یک جلسه دیگر از شما کسر شد'
                    FROM dbo.Attendance a, dbo.Member_Ship ms, dbo.Fighter_Public fp, dbo.Method m, dbo.Fighter c
                   WHERE a.CODE = @TempAttnCode
                     AND a.FIGH_FILE_NO = ms.FIGH_FILE_NO
                     AND ms.RWNO = @Mbsp_Rwno
                     AND ms.RECT_CODE = '004'
                     AND ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
                     AND ms.FGPB_RWNO_DNRM = fp.RWNO
                     AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
                     AND fp.MTOD_CODE = m.CODE
                     AND fp.COCH_FILE_NO = c.FILE_NO
               );   
               
               IF EXISTS (SELECT name FROM sys.databases WHERE name = N'iRoboTech')
	            BEGIN
	               --DECLARE @RoboServFileNo BIGINT;
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
         -- 1396/11/15 * ثبت پیامک تلگرام            
      END
           
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
      -- 1400/01/01 * ثبت خطای رخ داده شده درون سیستم
      INSERT INTO dbo.Log_Operation ( FIGH_FILE_NO ,LOID ,LOG_TYPE ,LOG_TEXT )
      VALUES   ( @Figh_File_No , 0 , '001' , @ErrorMessage );
   END CATCH   
END
GO
