SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ADM_MSAV_F]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN

	DECLARE @ErrorMessage NVARCHAR(MAX);
	BEGIN TRAN T1;
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
      
      --IF @RegnCode IS NULL OR @PrvnCode IS NULL 
         SELECT TOP 1 @RegnCode = CODE
                     ,@PrvnCode = PRVN_CODE
           FROM Region;
      IF @RqttCode IS NULL OR LEN(@RqttCode) < 3
         SET @RqttCode = '003';
         
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
      DECLARE @FileNo BIGINT;
      SELECT @FileNo = @X.query('//Fighter').value('(Fighter/@fileno)[1]', 'BIGINT');
      
      -- ثبت شماره پرونده 
      IF @FileNo IS NULL OR @FileNo = 0
      BEGIN
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
             ,@CbmtCode BIGINT
             ,@DayType VARCHAR(3)
             ,@AttnTime TIME(7)
             ,@CochCrtfDate DATE
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
             ,@IssuPLac NVARCHAR(100)
             ,@FathWork NVARCHAR(150)
             ,@HistDesc NVARCHAR(500)
             ,@IntrFileNo BIGINT
             ,@CntrCode BIGINT
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
             ,@RefCode BIGINT;
             
      SELECT @DiseCode = @X.query('//Dise_Code').value('.', 'BIGINT')
            ,@MtodCode = @X.query('//Mtod_Code').value('.', 'BIGINT')
            --,@CtgyCode = @X.query('//Ctgy_Code').value('.', 'BIGINT')
            --,@ClubCode = @X.query('//Club_Code').value('.', 'BIGINT')
            ,@FrstName = @X.query('//Frst_Name').value('.', 'NVARCHAR(250)')
            ,@LastName = @X.query('//Last_Name').value('.', 'NVARCHAR(250)')
            ,@FathName = @X.query('//Fath_Name').value('.', 'NVARCHAR(250)')
            ,@SexType  = @X.query('//Sex_Type').value('.', 'VARCHAR(3)')
            ,@NatlCode = @X.query('//Natl_Code').value('.', 'VARCHAR(10)')
            ,@BrthDate = @X.query('//Brth_Date').value('.', 'Date')
            ,@CellPhon = @X.query('//Cell_Phon').value('.', 'VARCHAR(11)')
            ,@TellPhon = @X.query('//Tell_Phon').value('.', 'VARCHAR(11)')
            ,@CochDeg  = @X.query('//Coch_Deg').value('.', 'VARCHAR(3)')
            ,@GudgDeg  = @X.query('//Gudg_Deg').value('.', 'VARCHAR(3)')
            ,@GlobCode = @X.query('//Glob_Code').value('.', 'VARCHAR(20)')
            ,@Type     = @X.query('//Type').value('.', 'VARCHAR(3)')
            ,@PostAdrs = @X.query('//Post_Adrs').value('.', 'NVARCHAR(1000)')
            ,@EmalAdrs = @X.query('//Emal_Adrs').value('.', 'VARCHAR(250)')
            ,@InsrNumb = @X.query('//Insr_Numb').value('.', 'VARCHAR(10)')
            ,@InsrDate = @X.query('//Insr_Date').value('.', 'DATE')
            ,@EducDeg  = @X.query('//Educ_Deg').value('.', 'VARCHAR(3)')
            --,@CbmtCode = @X.query('//Cbmt_Code').value('.', 'BIGINT');
            ,@CochCrtfDate = @X.query('//Coch_Crtf_Date').value('.', 'DATE')
            ,@CalcExpnType = @x.query('//Calc_Expn_Type').value('.', 'VARCHAR(3)')
            ,@BlodGrop = @x.query('//Blod_Grop').value('.', 'VARCHAR(3)')
            ,@FngrPrnt = @x.query('//Fngr_Prnt').value('.', 'VARCHAR(20)')
            ,@SuntBuntDeptOrgnCode = @x.query('//Sunt_Bunt_Dept_Orgn_Code').value('.', 'VARCHAR(2)')
            ,@SuntBuntDeptCode = @x.query('//Sunt_Bunt_Dept_Code').value('.', 'VARCHAR(2)')
            ,@SuntBuntCode = @x.query('//Sunt_Bunt_Code').value('.', 'VARCHAR(2)')
            ,@SuntCode = @x.query('//Sunt_Code').value('.', 'VARCHAR(4)')
            ,@CordX = @x.query('//Cord_X').value('.', 'REAL')
            ,@CordY = @x.query('//Cord_Y').value('.', 'REAL')
            ,@MostDebtClng = @x.query('//Most_Debt_Clng').value('.', 'BIGINT')
            ,@ServNo = @x.query('//Serv_No').value('.', 'NVARCHAR(50)')
            ,@BrthPlac = @x.query('//Brth_Palc').value('.', 'NVARCHAR(100)')
            ,@IssuPlac = @x.query('//Issu_Plac').value('.', 'NVARCHAR(100)')
            ,@FathWork = @x.query('//Fath_Work').value('.', 'NVARCHAR(150)')
            ,@HistDesc = @x.query('//Hist_Desc').value('.', 'NVARCHAR(500)')
            ,@IntrFileNo = @x.query('//Intr_File_No').value('.', 'BIGINT')
            ,@CntrCode = @x.query('//Cntr_Code').value('.', 'BIGINT')
            ,@DpstAcntSlryBank = @x.query('//Dpst_Acnt_Slry_Bank').value('.', 'NVARCHAR(50)')
            ,@DpstAcntSlry = @x.query('//Dpst_Acnt_Slry').value('.', 'VARCHAR(50)')
            ,@ChatId       = @x.query('//Chat_Id').value('.', 'BIGINT')
            ,@MomCellPhon = @x.query('//Mom_Cell_Phon').value('.', 'VARCHAR(11)')
            ,@MomTellPhon = @x.query('//Mom_Tell_Phon').value('.', 'VARCHAR(11)')
            ,@MomChatId = @x.query('//Mom_Chat_Id').value('.', 'BIGINT')
            ,@DadCellPhon = @x.query('//Dad_Cell_Phon').value('.', 'VARCHAR(11)')
            ,@DadTellPhon = @x.query('//Dad_Tell_Phon').value('.', 'VARCHAR(11)')
            ,@DadChatId = @x.query('//Dad_Chat_Id').value('.', 'BIGINT')
            ,@Password = @x.query('//Pass_Word').value('.', 'VARCHAR(250)')
            ,@RefCode = @x.query('//Ref_Code').value('.', 'BIGINT')
            
      SELECT @ActvTag = ISNULL(ACTV_TAG_DNRM, '101') FROM Fighter WHERE FILE_NO = @FileNo;

      -- Begin Check Validate
      IF LEN(@FrstName)        = 0 RAISERROR (N'برای فیلد "نام" درخواست اطلاعات وارد نشده' , 16, 1);
      IF LEN(@LastName)        = 0 RAISERROR (N'برای فیلد "نام خانوداگی" درخواست اطلاعات وارد نشده' , 16, 1);
      --IF LEN(@EducDeg)         = 0 RAISERROR (N'برای فیلد "مدرک تحصیلی" درخواست اطلاعات وارد نشده' , 16, 1);
      IF @BrthDate IN ('1900-01-01', '0001-01-01' ) RAISERROR (N'برای فیلد "تاریخ تولد" درخواست اطلاعات وارد نشده' , 16, 1);
      IF ISNULL(@MtodCode, 0)  = 0 RAISERROR (N'برای فیلد "سبک" درخواست اطلاعات وارد نشده' , 16, 1);
      IF LEN(@SexType)         = 0 RAISERROR (N'برای فیلد "جنسیت" درخواست اطلاعات وارد نشده' , 16, 1);
      IF ISNULL(@DiseCode, 0)  = 0 SET @DiseCode = NULL;
      --IF ISNULL(@CochDeg, 0)   = 0 RAISERROR (N'برای فیلد "درجه مربیگری" درخواست اطلاعات وارد نشده' , 16, 1);
      --IF ISNULL(@CalcExpnType, 0)   = 0 RAISERROR (N'برای فیلد "محاسبه دستمزد" درخواست اطلاعات وارد نشده' , 16, 1);
      --IF @CochCrtfDate IN ('1900-01-01', '0001-01-01') RAISERROR (N'برای فیلد "تاریخ مربیگری" درخواست اطلاعات وارد نشده' , 16, 1);
      IF LEN(@Type)            = 0 SET @TYPE = '003'--RAISERROR (N'برای فیلد "نوع هنرجو" درخواست اطلاعات وارد نشده' , 16, 1);
      --IF ISNULL(@CbmtCode , 0) = 0 AND @Type IN ('001', '004') RAISERROR(N'ساعت کلاسی برای هنرجو وارد نشده', 16, 1);
      IF LEN(@NatlCode)         = 0 RAISERROR (N'برای فیلد "کد ملی" اطلاعات وارد نشده' , 16, 1);
      
      SET @SuntBuntDeptOrgnCode = CASE LEN(@SuntBuntDeptOrgnCode) WHEN 2 THEN @SuntBuntDeptOrgnCode ELSE '00'   END;
      SET @SuntBuntDeptCode     = CASE LEN(@SuntBuntDeptCode)     WHEN 2 THEN @SuntBuntDeptCode     ELSE '00'   END;
      SET @SuntBuntCode         = CASE LEN(@SuntBuntCode)         WHEN 2 THEN @SuntBuntCode         ELSE '00'   END;
      SET @SuntCode             = CASE LEN(@SuntCode)             WHEN 4 THEN @SuntCode             ELSE '0000' END;

      
      IF ISNULL(@ClubCode, 0) = 0 AND (SELECT COUNT(CODE) FROM Club) >= 1
         SELECT TOP 1 @ClubCode = Code
           FROM Club;      
      
      IF ISNULL(@CtgyCode, 0) = 0
         SELECT @CtgyCode = Code
           FROM Category_Belt
          WHERE MTOD_CODE = @MtodCode
            AND ORDR = 0;      

      -- ثبت اطلاعات عمومی پرونده 
      IF NOT EXISTS(
         SELECT * 
         FROM Fighter_Public
         WHERE FIGH_FILE_NO = @FileNo
           AND RQRO_RQST_RQID = @Rqid
           AND RQRO_RWNO = @RqroRwno
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
           ,@Educ_Deg   = @EducDeg
           ,@Coch_File_No = @CochFileNo
           ,@Cbmt_Code = @CbmtCode
           ,@Day_Type = @DayType
           ,@Attn_Time = @AttnTime
           ,@Coch_Crtf_Date = @CochCrtfDate
           ,@Calc_Expn_Type = @CalcExpnType
           ,@Actv_Tag   = @ActvTag
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
           ,@IDTY_NUMB = @IDTYNUMB
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
           ,@Educ_Deg   = @EducDeg
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
           ,@IDTY_NUMB = @IDTYNUMB
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
      UPDATE Request
         SET RQST_STAT = '002'
       WHERE RQID = @Rqid;
      
      UPDATE Fighter
         SET CONF_STAT = '002'
       WHERE FILE_NO = @FileNo;
     
      -- 1396/09/04 * برای مربیان هم گزینه جدول تازیخ عضویت را وارد میکنیم
      DECLARE @StrtDate DATE = GETDATE()
             ,@EndDate DATE = DATEADD(YEAR, 2, GETDATE());
      
      SET @X = '<Process><Request rqstrqid="" rqtpcode="009" rqttcode="004" regncode="" prvncode=""><Request_Row fileno=""><Member_Ship strtdate="" enddate="" prntcont="1" numbmontofer="0" numbofattnmont="0" numbofattnweek="0" attndaytype="001"/></Request_Row></Request></Process>';
      SET @X.modify('replace value of (/Process/Request/@rqstrqid)[1] with sql:variable("@Rqid")');
      SET @X.modify('replace value of (/Process/Request/@regncode)[1] with sql:variable("@RegnCode")');
      SET @X.modify('replace value of (/Process/Request/@prvncode)[1] with sql:variable("@PrvnCode")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/@fileno)[1] with sql:variable("@FileNo")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@strtdate)[1] with sql:variable("@StrtDate")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@enddate)[1] with sql:variable("@EndDate")');      
      EXEC UCC_RQST_P @X;
      
      SELECT @Rqid = R.RQID
        FROM Request R
       WHERE R.RQST_RQID = @Rqid
         AND R.RQST_STAT = '001'
         AND R.RQTP_CODE = '009'
         AND R.RQTT_CODE = '004';

      SET @X = '<Process><Request rqid="" rqtpcode="009" rqttcode="004" regncode="" prvncode=""><Request_Row rwno="1" fileno=""><Member_Ship strtdate="" enddate="" prntcont="1" numbmontofer="0" numbofattnmont="0" numbofattnweek="0" attndaytype="001"/></Request_Row></Request></Process>';
      SET @X.modify('replace value of (/Process/Request/@rqid)[1] with sql:variable("@Rqid")');
      SET @X.modify('replace value of (/Process/Request/@regncode)[1] with sql:variable("@RegnCode")');
      SET @X.modify('replace value of (/Process/Request/@prvncode)[1] with sql:variable("@PrvnCode")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/@fileno)[1] with sql:variable("@FileNo")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@strtdate)[1] with sql:variable("@StrtDate")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@enddate)[1] with sql:variable("@EndDate")');
      EXEC UCC_SAVE_P @X;
      
      UPDATE dbo.Member_Ship
         SET FGPB_RWNO_DNRM = 1
            ,FGPB_RECT_CODE_DNRM = '004'
       WHERE RQRO_RQST_RQID = @Rqid;
                
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
