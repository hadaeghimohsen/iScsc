SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[PBL_SAVE_F]
	-- Add the parameters for the stored procedure here
	@X XML
	/* Sample Xml
   <Process>
      <Request rqid="" rqtpcode="" rqttcode="" regncode="" prvncode="">
         <Request_Row fileno="">
            <Fighter_Public>
               <Frst_Name></Frst_Name>
               <Last_Name></Last_Name>
               <Fath_Name></Fath_Name>
               <Sex_Type></Sex_Type>
               <Natl_Code></Natl_Code>
               <Brth_Date></Brth_Date>
               <Cell_Phon></Cell_Phon>
               <Tell_Phon></Tell_Phon>
               <Post_Adrs></Post_Adrs>
               <Emal_Adrs></Emal_Adrs>
               <Dise_Code></Dise_Code>
               <Mtod_Code></Mtod_Code>
               <Ctgy_Code></Ctgy_Code>
               <Club_Code></Club_Code>
               <Type></Type>
               <Coch_Deg></Coch_Deg>
               <Gudg_Deg></Gudg_Deg>
               <Glob_Code></Glob_Code>
               <Insr_Numb></Insr_Numb>
               <Insr_Date></Insr_Date>
            </Fighter_Public>
         </Request_Row>
      </Request>
   </Process>
*/
AS
BEGIN
	/*
	   شرایط ارسال داده ها مربوط به جدول درخواست
	   1 - درخواست جدید می باشد و ستون شماره درخواست خالی می باشد
	   2 - درخواست قبلا ثبت شده و ستون شماره درخواست خالی نمی باشد
	*/
   --RETURN;
   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>101</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 101 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END


	DECLARE @ErrorMessage NVARCHAR(MAX);
	BEGIN TRAN T$PBL_SAVE_F;
	BEGIN TRY
	   DECLARE @Rqid     BIGINT,
	           @RqtpCode VARCHAR(3),
	           @RqttCode VARCHAR(3),
	           @RegnCode VARCHAR(3),
	           @PrvnCode VARCHAR(3);
   	
	   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT')
	         ,@RqtpCode = @X.query('//Request').value('(Request/@rqtpcode)[1]', 'VARCHAR(3)')
	         ,@RqttCode = @X.query('//Request').value('(Request/@rqttcode)[1]', 'VARCHAR(3)')
	         ,@RegnCode = @X.query('//Request').value('(Request/@regncode)[1]', 'VARCHAR(3)')
	         ,@PrvnCode = @X.query('//Request').value('(Request/@prvncode)[1]', 'VARCHAR(3)');
      
      /* ثبت شماره درخواست */
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
      END
      ELSE
      /*BEGIN
         EXEC UPD_RQST_P
            @Rqid,
            @PrvnCode,
            @RegnCode,
            @RqtpCode,
            @RqttCode,
            NULL,
            NULL,
            NULL;            
      END
      */
      
      DECLARE @FileNo BIGINT;      

      DECLARE C$RQRV CURSOR FOR
         SELECT r.query('.').value('(Request_Row/@fileno)[1]', 'BIGINT')
           FROM @X.nodes('//Request_Row')Rr(r);
      
      OPEN C$RQRV;
      NextFromRqrv:
      FETCH NEXT FROM C$RQRV INTO @FileNo;
      
      IF @@FETCH_STATUS <> 0
         GOTO EndFetchRqrv;
      
            /* ثبت ردیف درخواست */
      DECLARE @RqroRwno SMALLINT;
      SET @RqroRwno = NULL;
      SELECT @RqroRwno = Rwno
         FROM Request_Row
         WHERE RQST_RQID = @Rqid
           AND FIGH_FILE_NO = @FileNo;
           
      /*IF @RqroRwno IS NULL
      BEGIN
         EXEC INS_RQRO_P
            @Rqid
           ,@FileNo
           ,@RqroRwno OUT;
      END*/
      
      DECLARE @DiseCode BIGINT
             ,@MtodCode BIGINT
             ,@CtgyCode BIGINT
             ,@ClubCode BIGINT
             ,@FrstName NVARCHAR(250)
             ,@LastName NVARCHAR(250)
             ,@FathName NVARCHAR(250)
             ,@SexType  VARCHAR(3)
             ,@NatlCode VARCHAR(10)
             ,@BrthDate DATE
             ,@CellPhon VARCHAR(11)
             ,@TellPhon VARCHAR(11)
             ,@CochDeg  VARCHAR(3)
             ,@GudgDeg  VARCHAR(3)
             ,@GlobCode VARCHAR(20)
             ,@Type     VARCHAR(3)
             ,@PostAdrs NVARCHAR(1000)
             ,@EmalAdrs NVARCHAR(250)
             ,@InsrNumb VARCHAR(10)
             ,@InsrDate DATE
             ,@EducDeg VARCHAR(3)
             ,@CochFileNo BIGINT
             ,@CochCrtfDate DATE
             ,@CbmtCode BIGINT
             ,@DayType VARCHAR(3)
             ,@AttnTime TIME(7)
             ,@CalcExpnType VARCHAR(3)
             ,@ActvTag VARCHAR(3)
             ,@BlodGrop VARCHAR(3)
             ,@FngrPrnt VARCHAR(20)
             ,@SuntBuntDeptOrgnCode VARCHAR(2)
             ,@SuntBuntDeptCode VARCHAR(2)
             ,@SuntBuntCode VARCHAR(2)
             ,@SuntCode VARCHAR(4)
             ,@CordX REAL
             ,@CordY REAL
             ,@MostDebtClng BIGINT
             ,@ServNo NVARCHAR(50)
             ,@BrthPlac NVARCHAR(100)
             ,@IssuPlac NVARCHAR(100)
             ,@FathWork NVARCHAR(150)
             ,@HistDesc NVARCHAR(500)
             --,@IntrFileNo BIGINT
             --,@CntrCode BIGINT
             ,@DpstAcntSlryBank NVARCHAR(50)
             ,@DpstAcntSlry VARCHAR(50)
             ,@ChatId BIGINT
             ,@MomCellPhon VARCHAR(11)
             ,@MomTellPhon VARCHAR(11)
             ,@MomChatId BIGINT
             ,@DadCellPhon VARCHAR(11)
             ,@DadTellPhon VARCHAR(11)
             ,@DadChatId BIGINT
             ,@IdtyNumb VARCHAR(20)
             --,@WatrFabrNumb NVARCHAR(30)
             --,@GasFabrNumb NVARCHAR(30)
             --,@PowrFabrNumb NVARCHAR(30)
             --,@BuldArea INT
             --,@ChldFmlyNumb SMALLINT
             --,@DpenFmlyNumb SMALLINT
             --,@FmlyNumb SMALLINT
             --,@HireDate DATETIME
             --,@HireType VARCHAR(3)
             --,@HirePlacCode BIGINT
             --,@HomeType VARCHAR(3)
             --,@HireCellPhon VARCHAR(11)
             --,@HireTellPhon VARCHAR(11)
             --,@SalrPlacCode BIGINT
             --,@UnitBlokCndoCode VARCHAR(3)
             --,@UnitBlokCode VARCHAR(3)
             --,@UnitCode VARCHAR(3)
             --,@PuntBlokCndoCode VARCHAR(3)
             --,@PuntBlokCode VARCHAR(3)
             --,@PuntCode VARCHAR(3)
             --,@PhasNumb SMALLINT
             --,@HireDegr VARCHAR(3)
             --,@HirePlacDegr VARCHAR(3)
             --,@ScorNumb SMALLINT
             --,@HomeRegnPrvnCntyCode VARCHAR(3)
             --,@HomeRegnPrvnCode VARCHAR(3)
             --,@HomeRegnCode VARCHAR(3)
             --,@HomePostAdrs NVARCHAR(1000)
             --,@HomeCordX FLOAT
             --,@HomeCordY FLOAT
             --,@HomeZipCode VARCHAR(10)
             ,@ZipCode VARCHAR(10)
             --,@RiskCode VARCHAR(20)
             --,@RiskNumb SMALLINT
             --,@WarDayNumb SMALLINT
             --,@CptvDayNumb SMALLINT
             --,@MridType VARCHAR(3)
             --,@JobTitlCode BIGINT
             ,@Cmnt NVARCHAR(4000)
             ,@Password VARCHAR(250)
             ,@RefCode BIGINT;
      
       SELECT @DiseCode = P.DISE_CODE
             ,@ClubCode = p.CLUB_CODE
             ,@FrstName = p.FRST_NAME
             ,@LastName = p.LAST_NAME
             ,@FathName = p.FATH_NAME
             ,@SexType  = p.SEX_TYPE
             ,@NatlCode = p.NATL_CODE
             ,@BrthDate = p.BRTH_DATE
             ,@CellPhon = p.CELL_PHON
             ,@TellPhon = p.TELL_PHON
             ,@CochDeg  = p.COCH_DEG
             ,@GudgDeg  = p.GUDG_DEG
             ,@GlobCode = p.GLOB_CODE
             ,@Type     = p.TYPE
             ,@PostAdrs = p.POST_ADRS
             ,@EmalAdrs = p.EMAL_ADRS
             ,@InsrNumb = p.INSR_NUMB
             ,@InsrDate = p.INSR_DATE
             ,@EducDeg  = p.EDUC_DEG
             ,@CochFileNo   = p.COCH_FILE_NO
             ,@CochCrtfDate = p.COCH_CRTF_DATE
             ,@CbmtCode     = p.CBMT_CODE
             ,@DayType      = p.DAY_TYPE
             ,@AttnTime     = p.ATTN_TIME
             ,@CalcExpnType = p.CALC_EXPN_TYPE
             ,@ActvTag = ISNULL(p.ACTV_TAG, '101')
             ,@BlodGrop = P.BLOD_GROP
             ,@FngrPrnt = P.FNGR_PRNT
             ,@SuntBuntDeptOrgnCode = P.Sunt_Bunt_Dept_Orgn_Code
             ,@SuntBuntDeptCode = P.Sunt_Bunt_Dept_Code
             ,@SuntBuntCode = P.Sunt_Bunt_Code
             ,@SuntCode = P.Sunt_Code
             ,@CordX = P.Cord_X
             ,@CordY = P.Cord_Y   
             ,@MostDebtClng = P.MOST_DEBT_CLNG          
             ,@ServNo = P.SERV_NO
             ,@BrthPlac = P.BRTH_PLAC
             ,@IssuPlac = P.ISSU_PLAC
             ,@FathWork = P.FATH_WORK
             ,@HistDesc = P.HIST_DESC
             --,@IntrFileNo = P.INTR_FILE_NO             
             --,@CntrCode = P.CNTR_CODE
             ,@DpstAcntSlryBank = P.DPST_ACNT_SLRY_BANK
             ,@DpstAcntSlry = P.DPST_ACNT_SLRY
             ,@ChatId = P.CHAT_ID
             ,@MomCellPhon = P.MOM_CELL_PHON
             ,@MomTellPhon = P.MOM_TELL_PHON
             ,@MomChatId = P.MOM_CHAT_ID
             ,@DadCellPhon = P.DAD_CELL_PHON
             ,@DadTellPhon = P.DAD_TELL_PHON
             ,@DadChatId = P.DAD_CHAT_ID
             ,@IdtyNumb = P.IDTY_NUMB
             ,@ZipCode = P.ZIP_CODE
             ,@Cmnt = P.CMNT             
             --,@UnitBlokCndoCode = P.UNIT_BLOK_CNDO_CODE
             --,@UnitBlokCode = P.UNIT_BLOK_CODE
             --,@UnitCode = P.UNIT_CODE
             ,@Password = P.PASS_WORD
             ,@RefCode = P.REF_CODE
         FROM Fighter_Public P
        WHERE P.FIGH_FILE_NO = @FileNo
          AND P.RQRO_RQST_RQID = @Rqid
          AND P.RQRO_RWNO = @RqroRwno
          AND P.RECT_CODE = '001';
      
      SELECT @MtodCode = MTOD_CODE_DNRM
            ,@CtgyCode = CTGY_CODE_DNRM
        FROM Fighter
       WHERE FILE_NO = @FileNo
         AND FGPB_TYPE_DNRM != '009';
      
      -- 1397/04/30
      DECLARE @TmpGlobCode VARCHAR(20);
      IF @GlobCode IS NULL OR @GlobCode = ''
      BEGIN
         SET @GlobCode = NULL;
         SELECT @TmpGlobCode = GLOB_CODE_DNRM
           FROM dbo.Fighter
          WHERE FILE_NO = @FileNo;
      END
      
      
      -- 1396/04/30 * بررسی اینکه تعداد جلسات برای مشترکین اشتراکی که تعداد جلسات در تعداد خانوار ضرب شود
      DECLARE @SharGlobCont INT = 1;
      IF (@GlobCode IS NOT NULL AND @GlobCode != '' AND LEN(@GlobCode) > 2 AND 
         EXISTS(
			   SELECT * 
			     FROM dbo.Member_Ship ms, dbo.Fighter_Public fp, dbo.Method m, dbo.Settings s
			    WHERE ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
			      AND ms.FGPB_RWNO_DNRM = fp.RWNO
			      AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
			      AND ms.RECT_CODE = '004'
			      AND fp.MTOD_CODE = m.CODE
			      AND m.CHCK_ATTN_ALRM = '002'
			      AND m.MTOD_STAT = '002'
			      AND fp.CLUB_CODE = s.CLUB_CODE
			      AND s.SHAR_MBSP_STAT = '002'
			      AND fp.GLOB_CODE = @GlobCode
			      AND ms.VALD_TYPE = '002'
	     )) OR 
	     (@GlobCode IS NULL AND (@TmpGlobCode IS NOT NULL OR @TmpGlobCode != '' AND LEN(@TmpGlobCode) > 2) )
      BEGIN
         SELECT @SharGlobCont = COUNT(*)
           FROM dbo.Fighter
          WHERE CONF_STAT = '002'
            AND ACTV_TAG_DNRM >= '101'
            AND GLOB_CODE_DNRM = CASE WHEN @GlobCode IS NULL THEN @TmpGlobCode ELSE @GlobCode END ;
      END;
      
      -- 1397/04/30 * بدست آوردن تعداد جلسات مصرف شده دیگر مشارکین
      DECLARE @OthrFileNo BIGINT,
              @SumAttnMont INT = 0,
              @NumbOfAttnMont INT = 0;
      IF @SharGlobCont > 1
      BEGIN
		SELECT TOP 1 @OthrFileNo = f.FILE_NO
		  FROM dbo.Fighter f
		 WHERE f.FILE_NO != @FileNo
		   AND f.GLOB_CODE_DNRM = CASE WHEN @GlobCode IS NULL THEN @TmpGlobCode ELSE @GlobCode END
		   AND f.CONF_STAT = '002'
		   AND f.ACTV_TAG_DNRM >= '101';
        
        SELECT @SumAttnMont = ms.SUM_ATTN_MONT_DNRM
              ,@NumbOfAttnMont = ms.NUMB_OF_ATTN_MONT / @SharGlobCont
          FROM dbo.Member_Ship ms, dbo.Fighter_Public fp, dbo.Method m
         WHERE ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
           AND ms.FGPB_RWNO_DNRM = fp.RWNO
           AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
           AND ms.FIGH_FILE_NO = @OthrFileNo
           AND ms.RECT_CODE = '004'
           AND fp.MTOD_CODE = m.CODE
           AND m.CHCK_ATTN_ALRM = '002' -- ورزش مشارکتی میباشد
           AND ISNULL(ms.NUMB_OF_ATTN_MONT, 0) > 0
		     --AND ISNULL(Ms.NUMB_OF_ATTN_MONT, 0) >= ISNULL(Ms.SUM_ATTN_MONT_DNRM, 0) 
           AND CAST(GETDATE() AS DATE) BETWEEN CAST(ms.STRT_DATE AS DATE) AND CAST(ms.END_DATE AS DATE)
           AND ms.VALD_TYPE = '002';
      END;
      
      -- 1397/04/30 *  ّبررسی کد پرسنلی برای مشترکین سیستم
      DECLARE @OldGlobCode VARCHAR(20);
      SELECT @OldGlobCode = ISNULL(GLOB_CODE_DNRM, '')
        FROM dbo.Fighter
       WHERE FILE_NO = @FileNo;
      
      IF @GlobCode IS NOT NULL AND @GlobCode != '' AND LEN(@GlobCode) >= 2
      BEGIN
         -- برای اضافه شدن فرد جدید به گزینه خانواده مشارکتی سیستم
         IF ISNULL(@OldGlobCode, '') = ''
         BEGIN
            -- اضافه شدن فرد جدید
            -- 1396/04/30 * ثبت گزینه ردیف عمومی
            UPDATE ms
               SET ms.NUMB_OF_ATTN_MONT = @NumbOfAttnMont * ( @SharGlobCont + 1 )
                  ,ms.SUM_ATTN_MONT_DNRM = @SumAttnMont -- در این قسمت باید بررسی شود که نفرهای قبلی آیا از گزینه استخر استفاده کرده اند یا خیر
              FROM dbo.Member_Ship ms, dbo.Fighter_Public fp, dbo.Method m
             WHERE ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
               AND ms.FGPB_RWNO_DNRM = fp.RWNO
               AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
               AND ms.FIGH_FILE_NO = @FileNo
               AND ms.RECT_CODE = '004'
               AND fp.MTOD_CODE = m.CODE
               AND m.CHCK_ATTN_ALRM = '002' -- ورزش مشارکتی میباشد
               AND ISNULL(ms.NUMB_OF_ATTN_MONT, 0) > 0
		         --AND ISNULL(Ms.NUMB_OF_ATTN_MONT, 0) >= ISNULL(Ms.SUM_ATTN_MONT_DNRM, 0) 
               AND CAST(GETDATE() AS DATE) BETWEEN CAST(ms.STRT_DATE AS DATE) AND CAST(ms.END_DATE AS DATE)
               AND ms.VALD_TYPE = '002';
            
            -- 1397/04/30 * اضافه کردن یک عضو به گروه
	         UPDATE ms
	            SET ms.NUMB_OF_ATTN_MONT = @NumbOfAttnMont * (@SharGlobCont + 1)
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
               AND ISNULL(ms.NUMB_OF_ATTN_MONT, 0) > 0
	            --AND ISNULL(Ms.NUMB_OF_ATTN_MONT, 0) >= ISNULL(Ms.SUM_ATTN_MONT_DNRM, 0) 
               AND CAST(GETDATE() AS DATE) BETWEEN CAST(ms.STRT_DATE AS DATE) AND CAST(ms.END_DATE AS DATE);
               
         END
         ELSE IF ISNULL(@OldGlobCode, '') <> @GlobCode
         BEGIN
            -- تعداد جلسات مربوط به گروه قبلی حذف شود و به گروه جدید اضافه شود            
            UPDATE ms
               SET ms.NUMB_OF_ATTN_MONT = @NumbOfAttnMont * ( @SharGlobCont + 1 )
                  ,ms.SUM_ATTN_MONT_DNRM = @SumAttnMont -- در این قسمت باید بررسی شود که نفرهای قبلی آیا از گزینه استخر استفاده کرده اند یا خیر
              FROM dbo.Member_Ship ms, dbo.Fighter_Public fp, dbo.Method m
             WHERE ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
               AND ms.FGPB_RWNO_DNRM = fp.RWNO
               AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
               AND ms.FIGH_FILE_NO = @FileNo
               AND ms.RECT_CODE = '004'
               AND fp.MTOD_CODE = m.CODE
               AND m.CHCK_ATTN_ALRM = '002' -- ورزش مشارکتی میباشد
               AND ISNULL(ms.NUMB_OF_ATTN_MONT, 0) > 0
		         --AND ISNULL(Ms.NUMB_OF_ATTN_MONT, 0) >= ISNULL(Ms.SUM_ATTN_MONT_DNRM, 0) 
               AND CAST(GETDATE() AS DATE) BETWEEN CAST(ms.STRT_DATE AS DATE) AND CAST(ms.END_DATE AS DATE)
               AND ms.VALD_TYPE = '002';

            -- 1397/04/30 * حذف کردن یک عضو از گروه
	         UPDATE ms
	            SET ms.NUMB_OF_ATTN_MONT -= @NumbOfAttnMont 
	           FROM dbo.Member_Ship ms, dbo.Fighter_Public fp, dbo.Method m
	          WHERE ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
	            AND ms.FGPB_RWNO_DNRM = fp.RWNO
	            AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
	            AND ms.RECT_CODE = '004'
	            AND ms.VALD_TYPE = '002'
	            AND ms.FIGH_FILE_NO != @FileNo
	            AND fp.MTOD_CODE = m.CODE
	            AND m.CHCK_ATTN_ALRM = '002' -- ورزش مشارکتی می باشد
	            AND fp.GLOB_CODE = @OldGlobCode
               AND ISNULL(ms.NUMB_OF_ATTN_MONT, 0) > 0
	            --AND ISNULL(Ms.NUMB_OF_ATTN_MONT, 0) >= ISNULL(Ms.SUM_ATTN_MONT_DNRM, 0) 
               AND CAST(GETDATE() AS DATE) BETWEEN CAST(ms.STRT_DATE AS DATE) AND CAST(ms.END_DATE AS DATE);
            
            -- 1397/04/30 * اضافه کردن یک عضو به گروه
	         UPDATE ms
	            SET ms.NUMB_OF_ATTN_MONT = @NumbOfAttnMont * (@SharGlobCont + 1)
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
               AND ISNULL(ms.NUMB_OF_ATTN_MONT, 0) > 0
	            --AND ISNULL(Ms.NUMB_OF_ATTN_MONT, 0) >= ISNULL(Ms.SUM_ATTN_MONT_DNRM, 0) 
               AND CAST(GETDATE() AS DATE) BETWEEN CAST(ms.STRT_DATE AS DATE) AND CAST(ms.END_DATE AS DATE);

         END
      END
      ELSE IF @GlobCode IS NULL OR @GlobCode = ''
      BEGIN
         -- برای حذف شدن فرد به گزینه خانواده مشارکتی سیستم
         SET @GlobCode = NULL;
         IF ISNULL(@OldGlobCode, '') <> ''
         BEGIN
            -- حذف کردن گزینه خانواده مشارکتی سیستم
            -- تعداد جلسات مربوط به گروه قبلی حذف شود و به گروه جدید اضافه شود            
            UPDATE ms
               SET ms.NUMB_OF_ATTN_MONT = @NumbOfAttnMont
                  ,ms.SUM_ATTN_MONT_DNRM = (SELECT COUNT(*) FROM dbo.Attendance a WHERE a.FIGH_FILE_NO = ms.FIGH_FILE_NO AND a.MTOD_CODE_DNRM = m.Code AND a.ATTN_STAT = '002' and a.ATTN_DATE BETWEEN CAST(ms.STRT_DATE AS DATE) AND CAST(ms.END_DATE AS DATE))
              FROM dbo.Member_Ship ms, dbo.Fighter_Public fp, dbo.Method m
             WHERE ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
               AND ms.FGPB_RWNO_DNRM = fp.RWNO
               AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
               AND ms.FIGH_FILE_NO = @FileNo
               AND ms.RECT_CODE = '004'
               AND fp.MTOD_CODE = m.CODE
               AND m.CHCK_ATTN_ALRM = '002' -- ورزش مشارکتی میباشد
               --AND fp.MTOD_CODE = @MtodCode
               AND ISNULL(ms.NUMB_OF_ATTN_MONT, 0) > 0
		         --AND ISNULL(Ms.NUMB_OF_ATTN_MONT, 0) >= ISNULL(Ms.SUM_ATTN_MONT_DNRM, 0) 
               AND CAST(GETDATE() AS DATE) BETWEEN CAST(ms.STRT_DATE AS DATE) AND CAST(ms.END_DATE AS DATE)
               AND ms.VALD_TYPE = '002';
            
            -- 1397/04/30 * حذف کردن یک عضو از گروه
	         UPDATE ms
	            SET ms.NUMB_OF_ATTN_MONT = @NumbOfAttnMont * (@SharGlobCont - 1)
	           FROM dbo.Member_Ship ms, dbo.Fighter_Public fp, dbo.Method m
	          WHERE ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
	            AND ms.FGPB_RWNO_DNRM = fp.RWNO
	            AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
	            AND ms.RECT_CODE = '004'
	            AND ms.VALD_TYPE = '002'
	            AND ms.FIGH_FILE_NO != @FileNo
	            AND fp.MTOD_CODE = m.CODE
	            AND m.CHCK_ATTN_ALRM = '002' -- ورزش مشارکتی می باشد
	            AND fp.GLOB_CODE = @OldGlobCode
               AND ISNULL(ms.NUMB_OF_ATTN_MONT, 0) > 0
	            --AND ISNULL(Ms.NUMB_OF_ATTN_MONT, 0) >= ISNULL(Ms.SUM_ATTN_MONT_DNRM, 0) 
               AND CAST(GETDATE() AS DATE) BETWEEN CAST(ms.STRT_DATE AS DATE) AND CAST(ms.END_DATE AS DATE);            
         END         
      END
      
      /* ثبت اطلاعات عمومی پرونده */
      IF NOT EXISTS(
         SELECT * 
         FROM Fighter_Public
         WHERE FIGH_FILE_NO = @FileNo
           AND RQRO_RQST_RQID = @Rqid
           AND RQRO_RWNO = @RqroRwno
           AND RECT_CODE = '004'
      )
      BEGIN
         EXEC INS_FGPB_P
            @Prvn_Code = @PrvnCode
           ,@Regn_Code = @RegnCode
           ,@File_No   = @FileNo
           ,@Dise_Code = @DiseCode
           ,@Mtod_Code = @MtodCode
           ,@Ctgy_Code = @CtgyCode
           ,@Club_Code = @ClubCode
           ,@Rqro_Rqst_Rqid = @Rqid
           ,@Rqro_Rwno = @RqroRwno
           ,@Rect_Code = '004'
           ,@Frst_Name = @FrstName
           ,@Last_Name = @LastName
           ,@Fath_Name = @FathName
           ,@Sex_Type = @SexType
           ,@Natl_Code = @NatlCode
           ,@Brth_Date = @BrthDate
           ,@Cell_Phon = @CellPhon
           ,@Tell_Phon = @TellPhon
           ,@Coch_Deg  = @CochDeg
           ,@Gudg_Deg = @GudgDeg
           ,@Glob_Code = @GlobCode
           ,@Type      = @Type
           ,@Post_Adrs = @PostAdrs
           ,@Emal_Adrs = @EmalAdrs
           ,@Insr_Numb = @InsrNumb
           ,@Insr_Date = @InsrDate
           ,@Educ_Deg = @EducDeg
           ,@Coch_File_No = @CochFileNo
           ,@Cbmt_Code = @CbmtCode
           ,@Day_Type = @DayType
           ,@Attn_Time = @AttnTime
           ,@Coch_Crtf_Date = @CochCrtfDate
           ,@Calc_Expn_Type = @CalcExpnType
           ,@Actv_Tag = @ActvTag
           ,@Blod_Grop = @BlodGrop
           ,@Fngr_Prnt = @FngrPrnt
           ,@Sunt_Bunt_Dept_Orgn_Code = @SuntBuntDeptOrgnCode
           ,@Sunt_Bunt_Dept_Code = @SuntBuntDeptCode
           ,@Sunt_Bunt_Code = @SuntBuntCode
           ,@Sunt_Code = @SuntCode
           ,@Cord_X = @CordX
           ,@Cord_Y = @CordY
           ,@Most_Debt_Clng = @MostDebtClng
           ,@Serv_No = @ServNo
           ,@Brth_Plac = @BrthPlac
           ,@Issu_Plac = @IssuPlac
           ,@Fath_Work = @FathWork
           ,@Hist_Desc = @HistDesc
           --,@Intr_File_No = @IntrFileNo
           --,@Cntr_Code = @CntrCode
           ,@Dpst_Acnt_Slry_Bank = @DpstAcntSlryBank
           ,@Dpst_Acnt_Slry = @DpstAcntSlry
           ,@Chat_Id = @ChatId
           ,@Mom_Cell_Phon = @MomCellPhon
           ,@Mom_Tell_Phon = @MomTellPhon
           ,@Mom_Chat_Id = @MomChatId
           ,@Dad_Cell_Phon = @DadCellPhon
           ,@Dad_Tell_Phon = @DadTellPhon
           ,@Dad_Chat_Id = @DadChatId
           ,@IDTY_NUMB = @IdtyNumb
           --,@WATR_FABR_NUMB = @WATRFABRNUMB
           --,@GAS_FABR_NUMB = @GASFABRNUMB
           --,@POWR_FABR_NUMB = @POWRFABRNUMB
           --,@BULD_AREA = @BULDAREA
           --,@CHLD_FMLY_NUMB = @CHLDFMLYNUMB
           --,@DPEN_FMLY_NUMB = @DPENFMLYNUMB
           --,@FMLY_NUMB = @FMLYNUMB
           --,@HIRE_DATE = @HIREDATE
           --,@HIRE_TYPE = @HIRETYPE
           --,@HIRE_PLAC_CODE = @HIREPLACCODE
           --,@HOME_TYPE = @HOMETYPE
           --,@HIRE_CELL_PHON = @HIRECELLPHON
           --,@HIRE_TELL_PHON = @HIRETELLPHON
           --,@SALR_PLAC_CODE = @SALRPLACCODE
           --,@UNIT_BLOK_CNDO_CODE = @UNITBLOKCNDOCODE
           --,@UNIT_BLOK_CODE = @UNITBLOKCODE
           --,@UNIT_CODE = @UNITCODE
           --,@PUNT_BLOK_CNDO_CODE = @PUNTBLOKCNDOCODE
           --,@PUNT_BLOK_CODE = @PUNTBLOKCODE
           --,@PUNT_CODE = @PUNTCODE
           --,@PHAS_NUMB = @PHASNUMB
           --,@HIRE_DEGR = @HIREDEGR
           --,@HIRE_PLAC_DEGR = @HIREPLACDEGR
           --,@SCOR_NUMB = @SCORNUMB
           --,@HOME_REGN_PRVN_CNTY_CODE = @HOMEREGNPRVNCNTYCODE
           --,@HOME_REGN_PRVN_CODE = @HOMEREGNPRVNCODE
           --,@HOME_REGN_CODE = @HOMEREGNCODE
           --,@HOME_POST_ADRS = @HOMEPOSTADRS
           --,@HOME_CORD_X = @HOMECORDX
           --,@HOME_CORD_Y = @HOMECORDY
           --,@HOME_ZIP_CODE = @HOMEZIPCODE
           ,@ZIP_CODE = @ZIPCODE
           --,@RISK_CODE = @RISKCODE
           --,@RISK_NUMB = @RISKNUMB
           --,@WAR_DAY_NUMB = @WARDAYNUMB
           --,@CPTV_DAY_NUMB = @CPTVDAYNUMB
           --,@MRID_TYPE = @MRIDTYPE
           --,@JOB_TITL_CODE = @JOBTITLCODE
           ,@CMNT = @CMNT
           ,@Pass_Word = @Password
           ,@Ref_Code = @RefCode;
      END
      ELSE
      BEGIN
         EXEC [UPD_FGPB_P]
            @Prvn_Code = @PrvnCode
           ,@Regn_Code = @RegnCode
           ,@File_No   = @FileNo
           ,@Dise_Code = @DiseCode
           ,@Mtod_Code = @MtodCode
           ,@Ctgy_Code = @CtgyCode
           ,@Club_Code = @ClubCode
           ,@Rqro_Rqst_Rqid = @Rqid
           ,@Rqro_Rwno = @RqroRwno
           ,@Rect_Code = '004'
           ,@Frst_Name = @FrstName
           ,@Last_Name = @LastName
           ,@Fath_Name = @FathName
           ,@Sex_Type = @SexType
           ,@Natl_Code = @NatlCode
           ,@Brth_Date = @BrthDate
           ,@Cell_Phon = @CellPhon
           ,@Tell_Phon = @TellPhon
           ,@Coch_Deg  = @CochDeg
           ,@Gudg_Deg = @GudgDeg
           ,@Glob_Code = @GlobCode
           ,@Type      = @Type
           ,@Post_Adrs = @PostAdrs
           ,@Emal_Adrs = @EmalAdrs
           ,@Insr_Numb = @InsrNumb
           ,@Insr_Date = @InsrDate
           ,@Educ_Deg = @EducDeg
           ,@Coch_File_No = @CochFileNo
           ,@Cbmt_Code = @CbmtCode
           ,@Day_Type = @DayType
           ,@Attn_Time = @AttnTime
           ,@Coch_Crtf_Date = @CochCrtfDate
           ,@Calc_Expn_Type = @CalcExpnType
           ,@Actv_Tag = @ActvTag
           ,@Blod_Grop = @BlodGrop
           ,@Fngr_Prnt = @FngrPrnt
           ,@Sunt_Bunt_Dept_Orgn_Code = @SuntBuntDeptOrgnCode
           ,@Sunt_Bunt_Dept_Code = @SuntBuntDeptCode
           ,@Sunt_Bunt_Code = @SuntBuntCode
           ,@Sunt_Code = @SuntCode
           ,@Cord_X = @CordX
           ,@Cord_Y = @CordY
           ,@Most_Debt_Clng = @MostDebtClng
           ,@Serv_No = @ServNo
           ,@Brth_Plac = @BrthPlac
           ,@Issu_Plac = @IssuPlac
           ,@Fath_Work = @FathWork
           ,@Hist_Desc = @HistDesc
           --,@Intr_File_No = @IntrFileNo
           --,@Cntr_Code = @CntrCode
           ,@Dpst_Acnt_Slry_Bank = @DpstAcntSlryBank
           ,@Dpst_Acnt_Slry = @DpstAcntSlry
           ,@Chat_Id = @ChatId
           ,@Mom_Cell_Phon = @MomCellPhon
           ,@Mom_Tell_Phon = @MomTellPhon
           ,@Mom_Chat_Id = @MomChatId
           ,@Dad_Cell_Phon = @DadCellPhon
           ,@Dad_Tell_Phon = @DadTellPhon
           ,@Dad_Chat_Id = @DadChatId
           ,@IDTY_NUMB = @IdtyNumb
           --,@WATR_FABR_NUMB = @WATRFABRNUMB
           --,@GAS_FABR_NUMB = @GASFABRNUMB
           --,@POWR_FABR_NUMB = @POWRFABRNUMB
           --,@BULD_AREA = @BULDAREA
           --,@CHLD_FMLY_NUMB = @CHLDFMLYNUMB
           --,@DPEN_FMLY_NUMB = @DPENFMLYNUMB
           --,@FMLY_NUMB = @FMLYNUMB
           --,@HIRE_DATE = @HIREDATE
           --,@HIRE_TYPE = @HIRETYPE
           --,@HIRE_PLAC_CODE = @HIREPLACCODE
           --,@HOME_TYPE = @HOMETYPE
           --,@HIRE_CELL_PHON = @HIRECELLPHON
           --,@HIRE_TELL_PHON = @HIRETELLPHON
           --,@SALR_PLAC_CODE = @SALRPLACCODE
           --,@UNIT_BLOK_CNDO_CODE = @UNITBLOKCNDOCODE
           --,@UNIT_BLOK_CODE = @UNITBLOKCODE
           --,@UNIT_CODE = @UNITCODE
           --,@PUNT_BLOK_CNDO_CODE = @PUNTBLOKCNDOCODE
           --,@PUNT_BLOK_CODE = @PUNTBLOKCODE
           --,@PUNT_CODE = @PUNTCODE
           --,@PHAS_NUMB = @PHASNUMB
           --,@HIRE_DEGR = @HIREDEGR
           --,@HIRE_PLAC_DEGR = @HIREPLACDEGR
           --,@SCOR_NUMB = @SCORNUMB
           --,@HOME_REGN_PRVN_CNTY_CODE = @HOMEREGNPRVNCNTYCODE
           --,@HOME_REGN_PRVN_CODE = @HOMEREGNPRVNCODE
           --,@HOME_REGN_CODE = @HOMEREGNCODE
           --,@HOME_POST_ADRS = @HOMEPOSTADRS
           --,@HOME_CORD_X = @HOMECORDX
           --,@HOME_CORD_Y = @HOMECORDY
           --,@HOME_ZIP_CODE = @HOMEZIPCODE
           ,@ZIP_CODE = @ZIPCODE
           --,@RISK_CODE = @RISKCODE
           --,@RISK_NUMB = @RISKNUMB
           --,@WAR_DAY_NUMB = @WARDAYNUMB
           --,@CPTV_DAY_NUMB = @CPTVDAYNUMB
           --,@MRID_TYPE = @MRIDTYPE
           --,@JOB_TITL_CODE = @JOBTITLCODE
           ,@CMNT = @CMNT
           ,@Pass_Word = @Password
           ,@Ref_Code = @RefCode;
      END
      
      /*DECLARE @AttnDate DATE;
      SET @AttnDate = GETDATE();
      
      IF NOT EXISTS(
      SELECT * 
        FROM Attendance A
       WHERE A.FIGH_FILE_NO = @FileNo
         AND CAST(A.ATTN_DATE AS DATE) = CAST(@AttnDate AS DATE)
      )   
         EXEC INS_ATTN_P @ClubCode, @FileNo, @AttnDate;
      */
      GOTO NextFromRqrv;
      EndFetchRqrv:
      CLOSE C$RQRV;
      DEALLOCATE C$RQRV;
      
      IF (SELECT COUNT(*)
           FROM Request_Row Rr
          WHERE Rr.RQST_RQID = @Rqid            
            AND Rr.RECD_STAT = '002') = 
          (SELECT COUNT(*)
           FROM Fighter_Public T
          WHERE T.RQRO_RQST_RQID = @Rqid            
            AND T.RECT_CODE = '004')            
      BEGIN
         SET @X = '<Process><Request rqid=""/></Process>';
         SET @X.modify(
            'replace value of (//Request/@rqid)[1]
             with sql:variable("@Rqid")'
         );         
         EXEC dbo.END_RQST_P @X;
      END
      
      -- 1399/12/07
      -- اگر این گزینه که مشتری کد برنامه بله خود را وارد کرده باشد
      IF ISNUMERIC(@ChatId) = 1
      BEGIN
         -- اگر شماره کد بله درون سیستم برای مشتری ثبت شده آن را برای سیستم باشگاه و فروشگاه آنلاین ثبت میکنیم
         IF EXISTS (SELECT name FROM sys.databases WHERE name = N'iRoboTech')
         BEGIN
            -- این برای سیستم موبایل باشگاه
            SELECT @X = (
               SELECT 12 AS '@subsys'
                     ,'102' AS '@cmndcode' -- عملیات جامع ذخیره سازی
                     ,5 AS '@refsubsys' -- محل ارجاعی
                     ,'appuser' AS '@execaslogin' -- توسط کدام کاربری اجرا شود               
                     ,(
                        SELECT FRST_NAME_DNRM AS '@frstname',
                               LAST_NAME_DNRM AS '@lastname',
                               CELL_PHON_DNRM AS '@cellphon',
                               NATL_CODE_DNRM AS '@natlcode',
                               5 AS '@subsys',
                               CHAT_ID_DNRM AS '@chatid',
                               391 AS '@rbid',
                               '010' AS '@actntype',
                               'reguser' AS '@cmndtext'                               
                          FROM dbo.Fighter
                         WHERE FILE_NO = @FileNo                          
                           FOR XML PATH('Service'), TYPE
                     )
                  FOR XML PATH('Router_Command')
            );
            EXEC dbo.RouterdbCommand @X = @X, @xRet = @X OUTPUT;
            -- این برای سیستم فروشگاه اینترنتی باشگاه
            SELECT @X = (
               SELECT 12 AS '@subsys'
                     ,'102' AS '@cmndcode' -- عملیات جامع ذخیره سازی
                     ,5 AS '@refsubsys' -- محل ارجاعی
                     ,'appuser' AS '@execaslogin' -- توسط کدام کاربری اجرا شود               
                     ,(
                        SELECT FRST_NAME_DNRM AS '@frstname',
                               LAST_NAME_DNRM AS '@lastname',
                               CELL_PHON_DNRM AS '@cellphon',
                               NATL_CODE_DNRM AS '@natlcode',
                               5 AS '@subsys',
                               CHAT_ID_DNRM AS '@chatid',
                               401 AS '@rbid',
                               '010' AS '@actntype',
                               'reguser' AS '@cmndtext'                               
                          FROM dbo.Fighter
                         WHERE FILE_NO = @FileNo                          
                           FOR XML PATH('Service'), TYPE
                     )
                  FOR XML PATH('Router_Command')
            );
            EXEC dbo.RouterdbCommand @X = @X, @xRet = @X OUTPUT;
         END
      END

      COMMIT TRAN T$PBL_SAVE_F;
   END TRY
   BEGIN CATCH
  	   IF (SELECT CURSOR_STATUS('local','C$RQRV')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$RQRV')) > -1
         BEGIN
          CLOSE C$RQRV
         END
       DEALLOCATE C$RQRV
      END

      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T$PBL_SAVE_F;
   END CATCH;   
END
GO
