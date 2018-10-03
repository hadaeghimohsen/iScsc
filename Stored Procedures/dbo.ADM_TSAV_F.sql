SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ADM_TSAV_F]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
   /*RAISERROR(N'گوه خوردی', 16, 1);
   RETURN;*/
   
   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>68</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 68 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END

   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>69</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 69 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>70</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 70 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END

	DECLARE @ErrorMessage NVARCHAR(MAX);
	BEGIN TRAN T$ADM_TSAV_F;
	BEGIN TRY
	   DECLARE @Rqid     BIGINT
	          ,@OrgnRqid BIGINT
	          ,@FileNo   BIGINT
	          ,@PrvnCode VARCHAR(3)
	          ,@RegnCode VARCHAR(3);   	
	          
	   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT')
	         ,@OrgnRqid = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT')
	         ,@PrvnCode = @X.query('//Request').value('(Request/@prvncode)[1]', 'VARCHAR(3)')
	         ,@RegnCode = @X.query('//Request').value('(Request/@regncode)[1]', 'VARCHAR(3)');
	         
      SELECT @FileNo = File_No, @PrvnCode = REGN_PRVN_CODE, @RegnCode = REGN_CODE
        FROM Fighter
       WHERE RQST_RQID = @Rqid;
      
      UPDATE Payment_Detail
         SET PAY_STAT = '002'
            ,RCPT_MTOD = @x.query('//Payment_Detail[@code=sql:column("Code")]').value('(Payment_Detail/@rcptmtod)[1]', 'VARCHAR(3)')
       WHERE PYMT_RQST_RQID = @Rqid
         AND @x.query('//Payment').value('(Payment/@setondebt)[1]', 'BIT') = 0;
      
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
             ,@Cmnt NVARCHAR(4000);
             

      SELECT @DiseCode     = P.DISE_CODE
            ,@MtodCode     = P.MTOD_CODE
            ,@CtgyCode     = P.CTGY_CODE
            ,@ClubCode     = P.CLUB_CODE
            ,@FrstName     = P.FRST_NAME
            ,@LastName     = P.LAST_NAME
            ,@FathName     = P.FATH_NAME
            ,@SexType      = P.SEX_TYPE
            ,@NatlCode     = P.NATL_CODE
            ,@BrthDate     = P.BRTH_DATE
            ,@CellPhon     = P.CELL_PHON
            ,@TellPhon     = P.TELL_PHON
            ,@CochDeg      = P.COCH_DEG
            ,@GudgDeg      = P.GUDG_DEG
            ,@GlobCode     = P.GLOB_CODE
            ,@Type         = CASE P.TYPE WHEN '004' THEN '001' ELSE P.TYPE END
            ,@PostAdrs     = P.POST_ADRS
            ,@EmalAdrs     = P.EMAL_ADRS
            ,@InsrNumb     = P.INSR_NUMB
            ,@InsrDate     = P.INSR_DATE
            ,@EducDeg      = P.EDUC_DEG
            ,@CochFileNo   = P.COCH_FILE_NO
            ,@CbmtCode     = P.CBMT_CODE
            ,@DayType      = P.DAY_TYPE
            ,@AttnTime     = P.ATTN_TIME
            ,@CochCrtfDate = P.COCH_CRTF_DATE
            ,@CalcExpnType = P.CALC_EXPN_TYPE
            ,@ActvTag      = ISNULL(P.ACTV_TAG, '101')
            ,@BlodGrop     = P.BLOD_GROP
            ,@FngrPrnt     = P.FNGR_PRNT
            ,@SuntBuntDeptOrgnCode = P.Sunt_Bunt_Dept_Orgn_Code
            ,@SuntBuntDeptCode = P.Sunt_Bunt_Dept_Code
            ,@SuntBuntCode = P.Sunt_Bunt_Code
            ,@SuntCode = P.Sunt_Code
            ,@CordX = P.Cord_X
            ,@CordY = P.Cord_Y
            ,@MostDebtClng = P.MOST_DEBT_CLNG
            ,@ServNo = P.Serv_No
            ,@BrthPlac = P.BRTH_PLAC
            ,@IssuPLac = P.ISSU_PLAC
            ,@FathWork = P.FATH_WORK
            ,@HistDesc = P.HIST_DESC
            ,@IntrFileNo = P.INTR_FILE_NO
            ,@CntrCode = P.CNTR_CODE
            ,@ChatId = P.CHAT_ID
            ,@MomCellPhon = P.MOM_CELL_PHON
            ,@MomTellPhon = P.MOM_TELL_PHON
            ,@MomChatId = P.MOM_CHAT_ID
            ,@DadCellPhon = P.DAD_CELL_PHON
            ,@DadTellPhon = P.DAD_TELL_PHON
            ,@DadChatId = P.DAD_CHAT_ID
        FROM Fighter_Public P
       WHERE P.FIGH_FILE_NO = @FileNo
         AND P.RQRO_RQST_RQID = @Rqid
         AND P.RQRO_RWNO = 1
         AND P.RECT_CODE = '001';
      
            
      IF NOT EXISTS(
         SELECT * 
         FROM Fighter_Public
         WHERE FIGH_FILE_NO = @FileNo
           AND RQRO_RQST_RQID = @Rqid
           AND RQRO_RWNO = 1
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
           ,@Rqro_Rwno = 1
           ,@Rect_Code = '004' -- ذخیره نهایی
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
           ,@CMNT = @CMNT;                      
      END
      
      UPDATE Fighter
         SET CONF_STAT = '002'
       WHERE RQST_RQID = @Rqid;
      
      UPDATE Request
         SET RQST_STAT = '002'
       WHERE RQID = @Rqid;
      
      -- مشخص مربی 
      UPDATE Payment_Detail
         SET FIGH_FILE_NO = @CochFileNo
            ,CBMT_CODE_DNRM = @CbmtCode
       WHERE PYMT_RQST_RQID = @Rqid;         
         
      DECLARE @StrtDate DateTime
             ,@EndDate  DATETIME
             ,@NumbMontOfer INT
             ,@NumbOfAttnMont INT
             ,@NumbOfAttnWeek INT
             ,@AttnDayType VARCHAR(3);
      
      SELECT @StrtDate = STRT_DATE, @EndDate = END_DATE
            ,@NumbMontOfer = NUMB_MONT_OFER
            ,@NumbOfAttnMont = NUMB_OF_ATTN_MONT
            ,@NumbOfAttnWeek = NUMB_OF_ATTN_WEEK
            ,@AttnDayType = ATTN_DAY_TYPE
        FROM Member_Ship
       WHERE RQRO_RQST_RQID = @Rqid
         AND FIGH_FILE_NO = @FileNo
         AND RECT_CODE = '001';
      

      SET @X = '<Process><Request rqstrqid="" rqtpcode="009" rqttcode="004" regncode="" prvncode=""><Request_Row fileno=""><Member_Ship strtdate="" enddate="" prntcont="1" numbmontofer="" numbofattnmont="" numbofattnweek="" attndaytype=""/></Request_Row></Request></Process>';
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
      EXEC UCC_RQST_P @X;
      
      SELECT @Rqid = R.RQID
        FROM Request R
       WHERE R.RQST_RQID = @Rqid
         AND R.RQST_STAT = '001'
         AND R.RQTP_CODE = '009'
         AND R.RQTT_CODE = '004';

      SET @X = '<Process><Request rqid="" rqtpcode="009" rqttcode="004" regncode="" prvncode=""><Request_Row rwno="1" fileno=""><Member_Ship strtdate="" enddate="" prntcont="1" numbmontofer="" numbofattnmont="" numbofattnweek="" attndaytype=""/></Request_Row></Request></Process>';
      SET @X.modify('replace value of (/Process/Request/@rqid)[1] with sql:variable("@Rqid")');
      SET @X.modify('replace value of (/Process/Request/@regncode)[1] with sql:variable("@RegnCode")');
      SET @X.modify('replace value of (/Process/Request/@prvncode)[1] with sql:variable("@PrvnCode")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/@fileno)[1] with sql:variable("@FileNo")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@strtdate)[1] with sql:variable("@StrtDate")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@enddate)[1] with sql:variable("@EndDate")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@numbmontofer)[1] with sql:variable("@NumbMontOfer")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@numbofattnmont)[1] with sql:variable("@NumbOfAttnMont")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@numbofattnweek)[1] with sql:variable("@NumbOfAttnWeek")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@attndaytype)[1] with sql:variable("@AttnDayType")');
      EXEC UCC_SAVE_P @X;
      
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
      IF EXISTS(SELECT * FROM dbo.Club_Method cm, dbo.Settings s WHERE cm.CLUB_CODE = s.CLUB_CODE AND s.SHAR_MBSP_STAT = '002' AND cm.CODE = @CbmtCode) AND @GlobCode IS NOT NULL AND @GlobCode != '' AND LEN(@GlobCode) > 2 AND EXISTS(SELECT * FROM dbo.Method WHERE CODE = @MtodCode AND CHCK_ATTN_ALRM = '002')
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
      
      -- 1396/10/13 * ثبت گزینه ردیف عمومی
      UPDATE dbo.Member_Ship
         SET FGPB_RWNO_DNRM = 1
            ,FGPB_RECT_CODE_DNRM = '004'
            ,END_DATE = DATEADD(DAY, @HldyNumb, END_DATE)
            ,NUMB_OF_ATTN_MONT = NUMB_OF_ATTN_MONT * @SharGlobCont
            ,SUM_ATTN_MONT_DNRM = @SumAttnMont -- در این قسمت باید بررسی شود که نفرهای قبلی آیا از گزینه استخر استفاده کرده اند یا خیر
       WHERE RQRO_RQST_RQID = @Rqid;
      
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
      --   SET @X = '<Process><Request rqstrqid="" rqtpcode="021" rqttcode="004" regncode="" prvncode=""><Request_Row fileno=""><Member_Ship strtdate="" enddate="" prntcont="1" numbmontofer="" numbofattnmont="" numbofattnweek="" attndaytype=""/></Request_Row></Request></Process>';
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
          WHERE MSGB_TYPE = '006';
         
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
                                   SELECT '006' AS '@type' 
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
          WHERE MSGB_TYPE = '006';
         
         IF @TelgStat = '002'
         BEGIN
            IF @InsrFnamStat = '002'
               SET @MsgbText = (SELECT DOMN_DESC FROM dbo.[D$SXDC] WHERE VALU = @SexType) + N' ' + @FrstName + N' ' + @LastName + N' ' ;--+ ISNULL(@MsgbText, N'');
            
            -- 1396/11/29 * اضافه کردن مبلغ هزینه دوره ثبت نامی 
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
            
            SELECT @MsgbText += (            
               SELECT CHAR(10) + N' شما در رشته ' + m.MTOD_DESC + N' با مربی ' + c.NAME_DNRM + N' برای ایام ' + d.DOMN_DESC + N' از ' + CAST(cm.STRT_TIME AS VARCHAR(5)) + N' تا ' + CAST(cm.END_TIME AS VARCHAR(5)) + N' ثبت نام کرده اید.' + 
                      CHAR(10) + N' مبلغ دوره شما ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, @ExpnAmnt), 1), '.00', '') + N' مبلغ پرداختی ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, @PymtAmnt), 1), '.00', '') + N' مبلغ تخفیف ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, @DscnPymt), 1), '.00', '') + 
                      CASE WHEN (@ExpnAmnt - (@PymtAmnt - @DscnPymt)) > 0 THEN CHAR(10) + N' میزان بدهی شما برای دوره ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, @ExpnAmnt - (@PymtAmnt - @DscnPymt)), 1), '.00', '') ELSE N' از پرداخت شما متشکریم ' END + 
                      CHAR(10) + N' از اینکه به جمع ما پیوستین بسیار خرسندیم. با آرزوی موفقیت و سلامتی برای شما' + 
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
                  AND ms.RWNO = 1
                  AND ms.RECT_CODE = '004'
            );
            
            --RAISERROR(@MsgbText, 16, 1);
            
            IF @InsrCnamStat = '002'
               SET @MsgbText = ISNULL(@MsgbText, N'') + N' ' + @ClubName;
            
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
      
      COMMIT TRAN T$ADM_TSAV_F;
   END TRY
   BEGIN CATCH
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T$ADM_TSAV_F;
   END CATCH;
END
GO
