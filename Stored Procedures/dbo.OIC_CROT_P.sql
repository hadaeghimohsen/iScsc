SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[OIC_CROT_P]
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
	BEGIN TRAN T1;
	BEGIN TRY
	   DECLARE @Rqid     BIGINT,
	           @RqtpCode VARCHAR(3),
	           @RqttCode VARCHAR(3),
	           @RegnCode VARCHAR(3),
	           @PrvnCode VARCHAR(3),
	           @ClubCode BIGINT,
	           @MdulName VARCHAR(11),
	           @SctnName VARCHAR(11),
	           @CardNumb VARCHAR(50),
	           @ExpnCode BIGINT,
	           @TotlSesn SMALLINT,
	           @FrstName NVARCHAR(250),
	           @LastName NVARCHAR(250),
	           @FathName NVARCHAR(250),
	           @BrthDate DATE,
	           @CbmtCode BIGINT,
	           @CochFileNo BIGINT,
	           @DayType VARCHAR(3),
	           @AttnTime TIME(0),
	           @SexType  VARCHAR(3),
	           @NatlCode VARCHAR(10),
	           @EducDeg  VARCHAR(3),
	           @InsrNumb VARCHAR(10),
	           @InsrDate DATE,
	           @DiseCode BIGINT,
	           @CellPhon VARCHAR(11),
	           @TellPhon VARCHAR(11),
	           @Blodgrop VARCHAR(3),
	           @EmalAdrs NVARCHAR(250),
	           @PostAdrs NVARCHAR(1000),
	           @FngrPrnt VARCHAR(20)
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
             ,@IntrFileNo BIGINT              
             ,@CntrCode BIGINT
             ,@ChatId BIGINT
             ,@MomCellPhon VARCHAR(11)
             ,@MomTellPhon VARCHAR(11)
             ,@MomChatId BIGINT
             ,@DadCellPhon VARCHAR(11)
             ,@DadTellPhon VARCHAR(11)
             ,@DadChatId BIGINT
             ,@IdtyNumb VARCHAR(20)
             ,@WatrFabrNumb NVARCHAR(30)
             ,@GasFabrNumb NVARCHAR(30)
             ,@PowrFabrNumb NVARCHAR(30)
             ,@BuldArea INT
             ,@ChldFmlyNumb SMALLINT
             ,@DpenFmlyNumb SMALLINT
             ,@FmlyNumb SMALLINT
             ,@HireDate DATETIME
             ,@HireType VARCHAR(3)
             ,@HirePlacCode BIGINT
             ,@HomeType VARCHAR(3)
             ,@HireCellPhon VARCHAR(11)
             ,@HireTellPhon VARCHAR(11)
             ,@SalrPlacCode BIGINT
             ,@UnitBlokCndoCode VARCHAR(3)
             ,@UnitBlokCode VARCHAR(3)
             ,@UnitCode VARCHAR(3)
             ,@PuntBlokCndoCode VARCHAR(3)
             ,@PuntBlokCode VARCHAR(3)
             ,@PuntCode VARCHAR(3)
             ,@PhasNumb SMALLINT
             ,@HireDegr VARCHAR(3)
             ,@HirePlacDegr VARCHAR(3)
             ,@ScorNumb SMALLINT
             ,@HomeRegnPrvnCntyCode VARCHAR(3)
             ,@HomeRegnPrvnCode VARCHAR(3)
             ,@HomeRegnCode VARCHAR(3)
             ,@HomePostAdrs NVARCHAR(1000)
             ,@HomeCordX FLOAT
             ,@HomeCordY FLOAT
             ,@HomeZipCode VARCHAR(10)
             ,@ZipCode VARCHAR(10)
             ,@RiskCode VARCHAR(20)
             ,@RiskNumb SMALLINT
             ,@WarDayNumb SMALLINT
             ,@CptvDayNumb SMALLINT
             ,@MridType VARCHAR(3)
             ,@JobTitlCode BIGINT
             ,@Cmnt NVARCHAR(4000)
             ,@Password VARCHAR(250)
	          ,@MtodCode BIGINT
	          ,@CtgyCode BIGINT
	          ,@StrtDate DATE
	          ,@EndDate DATE;
   	
   	DECLARE @FileNo BIGINT;
	   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT')
	         ,@RqtpCode = @X.query('//Request').value('(Request/@rqtpcode)[1]', 'VARCHAR(3)') -- 016
	         ,@RqttCode = @X.query('//Request').value('(Request/@rqttcode)[1]', 'VARCHAR(3)') -- 007
	         --,@RegnCode = @X.query('//Request').value('(Request/@regncode)[1]', 'VARCHAR(3)')
	         --,@PrvnCode = @X.query('//Request').value('(Request/@prvncode)[1]', 'VARCHAR(3)')
	         ,@ClubCode = @X.query('//Request').value('(Request/@clubcode)[1]', 'BIGINT')
	         ,@MdulName = @X.query('//Request').value('(Request/@mdulname)[1]', 'VARCHAR(11)')
	         ,@SctnName = @X.query('//Request').value('(Request/@sctnname)[1]', 'VARCHAR(11)')
	         	         
            ,@FileNo   = @X.query('//Fighter_Public').value('(Fighter_Public/@fighfileno)[1]', 'BIGINT')
	         ,@FrstName = @X.query('//Fighter_Public').value('(Fighter_Public/@frstname)[1]', 'NVARCHAR(250)')
	         ,@LastName = @X.query('//Fighter_Public').value('(Fighter_Public/@lastname)[1]', 'NVARCHAR(250)')
	         ,@BrthDate = @X.query('//Fighter_Public').value('(Fighter_Public/@brthdate)[1]', 'DATE')
	         --,@CbmtCode = @X.query('//Fighter_Public').value('(Fighter_Public/@cbmtcode)[1]', 'BIGINT')
	         ,@SexType  = @X.query('//Fighter_Public').value('(Fighter_Public/@sextype)[1]', 'VARCHAR(3)')
	         ,@FathName = @X.query('//Fighter_Public').value('(Fighter_Public/@fathname)[1]', 'NVARCHAR(250)')
	         ,@NatlCode = @X.query('//Fighter_Public').value('(Fighter_Public/@natlcode)[1]', 'VARCHAR(10)')
	         ,@EducDeg  = @X.query('//Fighter_Public').value('(Fighter_Public/@educdeg)[1]', 'VARCHAR(3)')
	         ,@InsrNumb = @X.query('//Fighter_Public').value('(Fighter_Public/@insrnumb)[1]', 'VARCHAR(10)')
	         ,@InsrDate = @X.query('//Fighter_Public').value('(Fighter_Public/@insrdate)[1]', 'DATE')
	         ,@DiseCode = @X.query('//Fighter_Public').value('(Fighter_Public/@disecode)[1]', 'BIGINT')
	         ,@CellPhon = @X.query('//Fighter_Public').value('(Fighter_Public/@cellphon)[1]', 'VARCHAR(11)')
	         ,@TellPhon = @X.query('//Fighter_Public').value('(Fighter_Public/@tellphon)[1]', 'VARCHAR(11)')
	         ,@Blodgrop = @X.query('//Fighter_Public').value('(Fighter_Public/@blodgrop)[1]', 'VARCHAR(3)')
	         ,@EmalAdrs = @X.query('//Fighter_Public').value('(Fighter_Public/@emaladrs)[1]', 'NVARCHAR(250)')
	         ,@PostAdrs = @X.query('//Fighter_Public').value('(Fighter_Public/@postadrs)[1]', 'NVARCHAR(1000)')
	         ,@FngrPrnt = @X.query('//Fighter_Public').value('(Fighter_Public/@fngrprnt)[1]', 'VARCHAR(20)')
	         ,@SuntBuntDeptOrgnCode = @X.query('//Fighter_Public').value('(Fighter_Public/@suntbuntdeptorgncode)[1]', 'VARCHAR(2)')
	         ,@SuntBuntDeptCode = @X.query('//Fighter_Public').value('(Fighter_Public/@suntbuntdeptcode)[1]', 'VARCHAR(2)')
	         ,@SuntBuntCode = @X.query('//Fighter_Public').value('(Fighter_Public/@suntbuntcode)[1]', 'VARCHAR(2)')
	         ,@SuntCode = @X.query('//Fighter_Public').value('(Fighter_Public/@suntcode)[1]', 'VARCHAR(4)')
	         ,@CordX = @X.query('//Fighter_Public').value('(Fighter_Public/@cordx)[1]', 'REAL')
	         ,@CordY = @X.query('//Fighter_Public').value('(Fighter_Public/@cordy)[1]', 'REAL')
	         ,@MostDebtClng = @X.query('//Fighter_Public').value('(Fighter_Public/@mostdebtclng)[1]', 'BIGINT')
	         ,@ServNo = @X.query('//Fighter_Public').value('(Fighter_Public/@servno)[1]', 'NVARCHAR(50)')
            ,@BrthPlac = @x.query('//Fighter_Public').value('(Fighter_Public/@brthplac)[1]', 'NVARCHAR(100)')
            ,@IssuPlac = @x.query('//Fighter_Public').value('(Fighter_Public/@issuplac)[1]', 'NVARCHAR(100)')
            ,@FathWork = @x.query('//Fighter_Public').value('(Fighter_Public/@fathwork)[1]', 'NVARCHAR(150)')
            ,@HistDesc = @x.query('//Fighter_Public').value('(Fighter_Public/@histdesc)[1]', 'NVARCHAR(500)')
            ,@IntrFileNo = @x.query('//Fighter_Public').value('(Fighter_Public/@intrfileno)[1]', 'BIGINT')	         
            ,@CntrCode = @x.query('//Fighter_Public').value('(Fighter_Public/@cntrcode)[1]', 'BIGINT')	         
	         ,@StrtDate = @X.query('//Member_Ship').value('(Member_Ship/@strtdate)[1]', 'DATE')
	         ,@EndDate  = @X.query('//Member_Ship').value('(Member_Ship/@enddate)[1]', 'DATE');
      
      IF LEN(@CardNumb) = 0 BEGIN RAISERROR(N'ورود شماره کارت الزامی می باشد', 16, 1); RETURN; END
      SELECT @RegnCode = REGN_CODE
            ,@PrvnCode = REGN_PRVN_CODE
        FROM dbo.Club
       WHERE Code = @ClubCode;

      IF EXISTS(
         SELECT * 
           FROM Fighter
          WHERE CARD_NUMB_DNRM = @CardNumb
      )
      BEGIN
         RAISERROR(N'این شماره کارت توسط فرد دیگری رزرو شده، لطفا شماره کارت دیگری را انتخاب کنید', 16, 1); 
         RETURN;
      END
      IF LEN(@FrstName) = 0 BEGIN RAISERROR(N'ورود نام الزامی می باشد', 16, 1); RETURN; END
      IF LEN(@LastName) = 0 BEGIN RAISERROR(N'ورود نام خانوادگی الزامی می باشد', 16, 1); RETURN; END
      IF @BrthDate = '1900-01-01' BEGIN /*RAISERROR(N'ورود تاریخ تولد الزامی می باشد', 16, 1); RETURN;*/ SET @BrthDate = DATEADD(YEAR, -24, GETDATE()); END
      IF @StrtDate = '1900-01-01' BEGIN /*RAISERROR(N'ورود تاریخ شروع جلسات الزامی می باشد', 16, 1);*/ SET @StrtDate = GETDATE(); END
      IF @EndDate = '1900-01-01' BEGIN /*RAISERROR(N'ورود تاریخ پایان جلسات الزامی می باشد', 16, 1); RETURN;*/ SET @EndDate = DATEADD(MONTH, 1, GETDATE()); END
      --IF ISNULL(@CbmtCode, 0) = 0 BEGIN RAISERROR(N'ورود ساعت کلاسی الزامی می باشد', 16, 1); RETURN; END
      IF LEN(@SexType) = 0 BEGIN RAISERROR(N'ورود جنسیت الزامی می باشد', 16, 1); RETURN; END
      IF @DiseCode = 0 BEGIN SET @DiseCode = NULL; END
      
      SET @SuntBuntDeptOrgnCode = CASE LEN(@SuntBuntDeptOrgnCode) WHEN 2 THEN @SuntBuntDeptOrgnCode ELSE '00'   END;
      SET @SuntBuntDeptCode     = CASE LEN(@SuntBuntDeptCode)     WHEN 2 THEN @SuntBuntDeptCode     ELSE '00'   END;
      SET @SuntBuntCode         = CASE LEN(@SuntBuntCode)         WHEN 2 THEN @SuntBuntCode         ELSE '00'   END;
      SET @SuntCode             = CASE LEN(@SuntCode)             WHEN 4 THEN @SuntCode             ELSE '0000' END;

      SELECT @CochFileNo = COCH_FILE_NO
            ,@DayType = DAY_TYPE
            ,@AttnTime = STRT_TIME
        FROM Club_Method
       WHERE CODE = @CbmtCode;
       
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
      ELSE
      BEGIN
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


      -- ثبت یا به کارگیری مشترک رزرو ساعتی در جدول های مربوطه
      
      /*SELECT @MtodCode = MTOD_CODE
            ,@CtgyCode = CTGY_CODE
        FROM Expense
       WHERE CODE = @ExpnCode;*/
      
      
      IF @FileNo IS NULL OR @FileNo = 0
      BEGIN
         -- ثبت شماره پرونده 
         EXEC dbo.INS_FIGH_P @Rqid, @PrvnCode, @RegnCode, @FileNo OUT;
      END   
      -- ثبت ردیف درخواست 
      DECLARE @RqroRwno SMALLINT;
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
      
      /* ثبت اطلاعات عمومی پرونده */
      IF NOT EXISTS(
         SELECT * 
         FROM Fighter_Public
         WHERE FIGH_FILE_NO = @FileNo
           AND RQRO_RQST_RQID = @Rqid
           AND RQRO_RWNO = @RqroRwno
           AND RECT_CODE = '001'
      )
      BEGIN
         EXEC INS_FGPB_P
            @Prvn_Code = @PrvnCode
           ,@Regn_Code = @RegnCode
           ,@File_No   = @FileNo
           ,@Dise_Code = @DiseCode
           ,@Mtod_Code = NULL
           ,@Ctgy_Code = NULL
           ,@Club_Code = @ClubCode
           ,@Rqro_Rqst_Rqid = @Rqid
           ,@Rqro_Rwno = @RqroRwno
           ,@Rect_Code = '001'
           ,@Frst_Name = @FrstName
           ,@Last_Name = @LastName
           ,@Fath_Name = @FathName
           ,@Sex_Type = @SexType
           ,@Natl_Code = @NatlCode
           ,@Brth_Date = @BrthDate
           ,@Cell_Phon = @CellPhon
           ,@Tell_Phon = @TellPhon
           ,@Coch_Deg  = NULL
           ,@Gudg_Deg = NULL
           ,@Glob_Code = NULL
           ,@Type      = '009'
           ,@Post_Adrs = @PostAdrs
           ,@Emal_Adrs = @EmalAdrs
           ,@Insr_Numb = @InsrNumb
           ,@Insr_Date = @InsrDate
           ,@Educ_Deg   = @EducDeg
           ,@Coch_File_No = NULL
           ,@Cbmt_Code = NULL
           ,@Day_Type = NULL
           ,@Attn_Time = NULL
           ,@Coch_Crtf_Date = NULL
           ,@Calc_Expn_Type = NULL
           ,@Actv_Tag = '101'
           ,@Blod_Grop = @Blodgrop
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
           ,@Intr_File_No = @IntrFileNo
           ,@Cntr_Code = @CntrCode
           ,@Dpst_Acnt_Slry_Bank = NULL
           ,@Dpst_Acnt_Slry = NULL
           ,@Chat_Id = @ChatId
           ,@Mom_Cell_Phon = @MomCellPhon
           ,@Mom_Tell_Phon = @MomTellPhon
           ,@Mom_Chat_Id = @MomChatId
           ,@Dad_Cell_Phon = @DadCellPhon
           ,@Dad_Tell_Phon = @DadTellPhon
           ,@Dad_Chat_Id = @DadChatId
           ,@IDTY_NUMB = @IDTYNUMB
           ,@WATR_FABR_NUMB = @WATRFABRNUMB
           ,@GAS_FABR_NUMB = @GASFABRNUMB
           ,@POWR_FABR_NUMB = @POWRFABRNUMB
           ,@BULD_AREA = @BULDAREA
           ,@CHLD_FMLY_NUMB = @CHLDFMLYNUMB
           ,@DPEN_FMLY_NUMB = @DPENFMLYNUMB
           ,@FMLY_NUMB = @FMLYNUMB
           ,@HIRE_DATE = @HIREDATE
           ,@HIRE_TYPE = @HIRETYPE
           ,@HIRE_PLAC_CODE = @HIREPLACCODE
           ,@HOME_TYPE = @HOMETYPE
           ,@HIRE_CELL_PHON = @HIRECELLPHON
           ,@HIRE_TELL_PHON = @HIRETELLPHON
           ,@SALR_PLAC_CODE = @SALRPLACCODE
           ,@UNIT_BLOK_CNDO_CODE = @UNITBLOKCNDOCODE
           ,@UNIT_BLOK_CODE = @UNITBLOKCODE
           ,@UNIT_CODE = @UNITCODE
           ,@PUNT_BLOK_CNDO_CODE = @PUNTBLOKCNDOCODE
           ,@PUNT_BLOK_CODE = @PUNTBLOKCODE
           ,@PUNT_CODE = @PUNTCODE
           ,@PHAS_NUMB = @PHASNUMB
           ,@HIRE_DEGR = @HIREDEGR
           ,@HIRE_PLAC_DEGR = @HIREPLACDEGR
           ,@SCOR_NUMB = @SCORNUMB
           ,@HOME_REGN_PRVN_CNTY_CODE = @HOMEREGNPRVNCNTYCODE
           ,@HOME_REGN_PRVN_CODE = @HOMEREGNPRVNCODE
           ,@HOME_REGN_CODE = @HOMEREGNCODE
           ,@HOME_POST_ADRS = @HOMEPOSTADRS
           ,@HOME_CORD_X = @HOMECORDX
           ,@HOME_CORD_Y = @HOMECORDY
           ,@HOME_ZIP_CODE = @HOMEZIPCODE
           ,@ZIP_CODE = @ZIPCODE
           ,@RISK_CODE = @RISKCODE
           ,@RISK_NUMB = @RISKNUMB
           ,@WAR_DAY_NUMB = @WARDAYNUMB
           ,@CPTV_DAY_NUMB = @CPTVDAYNUMB
           ,@MRID_TYPE = @MRIDTYPE
           ,@JOB_TITL_CODE = @JOBTITLCODE
           ,@CMNT = @CMNT
           ,@Pass_Word = @Password;
      END
      ELSE
      BEGIN
         EXEC UPD_FGPB_P
            @Prvn_Code = @PrvnCode
           ,@Regn_Code = @RegnCode
           ,@File_No   = @FileNo
           ,@Dise_Code = @DiseCode
           ,@Mtod_Code = NULL
           ,@Ctgy_Code = NULL
           ,@Club_Code = @ClubCode
           ,@Rqro_Rqst_Rqid = @Rqid
           ,@Rqro_Rwno = @RqroRwno
           ,@Rect_Code = '001'
           ,@Frst_Name = @FrstName
           ,@Last_Name = @LastName
           ,@Fath_Name = @FathName
           ,@Sex_Type = @SexType
           ,@Natl_Code = @NatlCode
           ,@Brth_Date = @BrthDate
           ,@Cell_Phon = @CellPhon
           ,@Tell_Phon = @TellPhon
           ,@Coch_Deg  = NULL
           ,@Gudg_Deg = NULL
           ,@Glob_Code = NULL
           ,@Type      = '009'
           ,@Post_Adrs = @PostAdrs
           ,@Emal_Adrs = @EmalAdrs
           ,@Insr_Numb = @InsrNumb
           ,@Insr_Date = @InsrDate
           ,@Educ_Deg   = @EducDeg
           ,@Coch_File_No = NULL
           ,@Cbmt_Code = NULL
           ,@Day_Type = NULL
           ,@Attn_Time = NULL
           ,@Coch_Crtf_Date = NULL
           ,@Calc_Expn_Type = NULL
           ,@Actv_Tag = '101'
           ,@Blod_Grop = @Blodgrop
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
           ,@Intr_File_No = @IntrFileNo
           ,@Cntr_Code = @CntrCode
           ,@Dpst_Acnt_Slry_Bank = NULL
           ,@Dpst_Acnt_Slry = NULL
           ,@Chat_Id = @ChatId
           ,@Mom_Cell_Phon = @MomCellPhon
           ,@Mom_Tell_Phon = @MomTellPhon
           ,@Mom_Chat_Id = @MomChatId
           ,@Dad_Cell_Phon = @DadCellPhon
           ,@Dad_Tell_Phon = @DadTellPhon
           ,@Dad_Chat_Id = @DadChatId
           ,@IDTY_NUMB = @IDTYNUMB
           ,@WATR_FABR_NUMB = @WATRFABRNUMB
           ,@GAS_FABR_NUMB = @GASFABRNUMB
           ,@POWR_FABR_NUMB = @POWRFABRNUMB
           ,@BULD_AREA = @BULDAREA
           ,@CHLD_FMLY_NUMB = @CHLDFMLYNUMB
           ,@DPEN_FMLY_NUMB = @DPENFMLYNUMB
           ,@FMLY_NUMB = @FMLYNUMB
           ,@HIRE_DATE = @HIREDATE
           ,@HIRE_TYPE = @HIRETYPE
           ,@HIRE_PLAC_CODE = @HIREPLACCODE
           ,@HOME_TYPE = @HOMETYPE
           ,@HIRE_CELL_PHON = @HIRECELLPHON
           ,@HIRE_TELL_PHON = @HIRETELLPHON
           ,@SALR_PLAC_CODE = @SALRPLACCODE
           ,@UNIT_BLOK_CNDO_CODE = @UNITBLOKCNDOCODE
           ,@UNIT_BLOK_CODE = @UNITBLOKCODE
           ,@UNIT_CODE = @UNITCODE
           ,@PUNT_BLOK_CNDO_CODE = @PUNTBLOKCNDOCODE
           ,@PUNT_BLOK_CODE = @PUNTBLOKCODE
           ,@PUNT_CODE = @PUNTCODE
           ,@PHAS_NUMB = @PHASNUMB
           ,@HIRE_DEGR = @HIREDEGR
           ,@HIRE_PLAC_DEGR = @HIREPLACDEGR
           ,@SCOR_NUMB = @SCORNUMB
           ,@HOME_REGN_PRVN_CNTY_CODE = @HOMEREGNPRVNCNTYCODE
           ,@HOME_REGN_PRVN_CODE = @HOMEREGNPRVNCODE
           ,@HOME_REGN_CODE = @HOMEREGNCODE
           ,@HOME_POST_ADRS = @HOMEPOSTADRS
           ,@HOME_CORD_X = @HOMECORDX
           ,@HOME_CORD_Y = @HOMECORDY
           ,@HOME_ZIP_CODE = @HOMEZIPCODE
           ,@ZIP_CODE = @ZIPCODE
           ,@RISK_CODE = @RISKCODE
           ,@RISK_NUMB = @RISKNUMB
           ,@WAR_DAY_NUMB = @WARDAYNUMB
           ,@CPTV_DAY_NUMB = @CPTVDAYNUMB
           ,@MRID_TYPE = @MRIDTYPE
           ,@JOB_TITL_CODE = @JOBTITLCODE
           ,@CMNT = @CMNT
           ,@Pass_Word = @Password;
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
         VALUES                  (@Rqid,         @RqroRwno, @FileNo,      '001',     '001', @StrtDate, @EndDate);
      END
      ELSE
         UPDATE Member_Ship
            SET STRT_DATE = @StrtDate
               ,END_DATE = @EndDate
          WHERE RQRO_RQST_RQID = @Rqid
            AND RQRO_RWNO = @RqroRwno
            AND FIGH_FILE_NO = @FileNo
            AND [TYPE] = '001'
            AND RECT_CODE = '001';
      
      DECLARE @MbspRwno SMALLINT;
      SELECT @MbspRwno = RWNO
        FROM Member_Ship
       WHERE RQRO_RQST_RQID = @Rqid
         AND RQRO_RWNO = @RqroRwno
         AND FIGH_FILE_NO = @FileNo
         AND [TYPE] = '001'
         AND RECT_CODE = '001';
      
      DECLARE C$Sessions CURSOR FOR
         SELECT r.query('.').value('(Session/@snid)[1]', 'BIGINT')
               ,r.query('.').value('(Session/@expncode)[1]', 'BIGINT')
	            ,r.query('.').value('(Session/@totlsesn)[1]', 'SMALLINT')
	            ,r.query('.').value('(Session/@cbmtcode)[1]', 'BIGINT')
         FROM @X.nodes('//Session') T(r)
      
      DECLARE @TotlAttnNumb INT = 0;
      DECLARE @Snid BIGINT;
      
      OPEN C$Sessions;
      Fetch_C$Sessions:
      FETCH NEXT FROM C$Sessions INTO @Snid, @ExpnCode, @TotlSesn, @CbmtCode;
      
      IF @@FETCH_STATUS <> 0
         GOTO End_C$Session;

      IF @ExpnCode = 0 BEGIN CLOSE C$Sessions; DEALLOCATE C$Sessions; RAISERROR(N'ورود شرکت در جلسه الزامی می باشد', 16, 1); RETURN; END
      IF @TotlSesn = 0 BEGIN CLOSE C$Sessions; DEALLOCATE C$Sessions; RAISERROR(N'ورود تعداد جلسات الزامی می باشد', 16, 1); RETURN; END
      IF @TotlSesn < 1 BEGIN CLOSE C$Sessions; DEALLOCATE C$Sessions; RAISERROR(N'تعداد جلسات باید بیشتر یک جلسه باشد', 16, 1); RETURN; END
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
         UPDATE [Session]
            SET EXPN_CODE = @ExpnCode
               ,CARD_NUMB = @FngrPrnt
               ,TOTL_SESN = @TotlSesn
               ,CBMT_CODE = @CbmtCode
          WHERE MBSP_FIGH_FILE_NO = @FileNo
            AND MBSP_RECT_CODE = '001'
            AND MBSP_RWNO = @MbspRwno
            AND SNID = @Snid;
      
      /*SELECT @TotlAttnNumb += TOTL_SESN
        FROM dbo.Session
       WHERE MBSP_FIGH_FILE_NO = @FileNo
         AND MBSP_RECT_CODE = '001'
         AND MBSP_RWNO = @MbspRwno
         AND EXPN_CODE = @ExpnCode;*/
      SET @TotlAttnNumb = @TotlAttnNumb + @TotlSesn;
      
      GOTO Fetch_C$Sessions;
      End_C$Session:
      CLOSE C$Sessions;
      DEALLOCATE C$Sessions;
      
      -- 1396/05/09 * برای ذخیره کردن تعداد کل جلسات مشتری
      UPDATE Member_Ship
         SET NUMB_OF_ATTN_MONT = @TotlAttnNumb
       WHERE RQRO_RQST_RQID = @Rqid
         AND RQRO_RWNO = @RqroRwno
         AND FIGH_FILE_NO = @FileNo
         AND [TYPE] = '001'
         AND RECT_CODE = '001';
      
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
END;
GO
