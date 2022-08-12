SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[PIN_SAVE_F]
	@X XML
AS
BEGIN
   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>133</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 133 سطوح امینتی', -- Message text.
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
	           @PrvnCode VARCHAR(3);
   	
	   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT')
	         ,@RqtpCode = @X.query('//Request').value('(Request/@rqtpcode)[1]', 'VARCHAR(3)')
	         ,@RqttCode = @X.query('//Request').value('(Request/@rqttcode)[1]', 'VARCHAR(3)')
	         ,@RegnCode = @X.query('//Request').value('(Request/@regncode)[1]', 'VARCHAR(3)')
	         ,@PrvnCode = @X.query('//Request').value('(Request/@prvncode)[1]', 'VARCHAR(3)');
      
      UPDATE Payment_Detail
         SET PAY_STAT = '002'
            ,RCPT_MTOD = @x.query('//Payment_Detail[@code=sql:column("Code")]').value('(Payment_Detail/@rcptmtod)[1]', 'VARCHAR(3)')
       WHERE PYMT_RQST_RQID = @Rqid;
     
      DECLARE @FileNo BIGINT;      

      DECLARE C$RQRV CURSOR FOR
         SELECT r.query('.').value('(Request_Row/@fileno)[1]', 'BIGINT')
           FROM @X.nodes('//Request_Row')Rr(r);
      
      OPEN C$RQRV;
      NextFromRqrv:
      FETCH NEXT FROM C$RQRV INTO @FileNo;
      
      IF @@FETCH_STATUS <> 0
         GOTO EndFetchRqrv;
      
      DECLARE @RqroRwno SMALLINT;
      SET @RqroRwno = NULL;
      SELECT @RqroRwno = Rwno
         FROM Request_Row
         WHERE RQST_RQID = @Rqid
           AND FIGH_FILE_NO = @FileNo;
      
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
             ,@Password = P.PASS_WORD
             ,@RefCode = P.REF_CODE
         FROM Fighter_Public P
        WHERE P.FIGH_FILE_NO = @FileNo
          AND P.RQRO_RQST_RQID = @Rqid
          AND P.RQRO_RWNO = @RqroRwno
          AND P.RECT_CODE = '001';
      
      SELECT @MtodCode = MTOD_CODE_DNRM
            ,@CtgyCode = CTGY_CODE_DNRM
            ,@PrvnCode = REGN_PRVN_CODE
            ,@RegnCode = REGN_CODE
        FROM Fighter
       WHERE FILE_NO = @FileNo;
      
      IF LEN(@InsrNumb) = 0 RAISERROR(N'شماره بیمه وارد نشده است', 16, 1);
      IF @InsrDate      = '1900-01-01' RAISERROR (N'تاریخ بیمه اطلاعات وارد نشده' , 16, 1);
      
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
      
      -- 1398/06/30 * سامانه پیامکی
      IF @CellPhon IS NOT NULL AND LEN(@CellPhon) != 0 AND EXISTS(SELECT * FROM dbo.Request WHERE RQID = @Rqid AND RQTT_CODE = '001')
      BEGIN
         DECLARE @MsgbStat VARCHAR(3)
                ,@MsgbText NVARCHAR(MAX)
                ,@ClubName NVARCHAR(250)
                ,@InsrCnamStat VARCHAR(3)
                ,@InsrFnamStat VARCHAR(3)
                ,@LineType VARCHAR(3)
                ,@SendInfo VARCHAR(3)
                ,@AmntType VARCHAR(3)
                ,@AmntTypeDesc NVARCHAR(255)
                ,@MesgInfo NVARCHAR(MAX)
                ,@MinNumbDayRmnd int;
                
         SELECT @MsgbStat = STAT
               ,@MsgbText = MSGB_TEXT
               ,@ClubName = CLUB_NAME
               ,@InsrCnamStat = INSR_CNAM_STAT
               ,@InsrFnamStat = INSR_FNAM_STAT
               ,@LineType = LINE_TYPE
               ,@SendInfo = SEND_INFO
           FROM dbo.Message_Broadcast
          WHERE MSGB_TYPE = '011';
         
  	      SELECT @AmntType = rg.AMNT_TYPE, 
	             @AmntTypeDesc = d.DOMN_DESC
	        FROM iScsc.dbo.Regulation rg, iScsc.dbo.[D$ATYP] d
	       WHERE rg.TYPE = '001'
	         AND rg.REGL_STAT = '002'
	         AND rg.AMNT_TYPE = d.VALU;
         
         IF @MsgbStat = '002' 
         BEGIN
            IF @InsrFnamStat = '002'
               SET @MsgbText = (SELECT DOMN_DESC FROM dbo.[D$SXDC] WHERE VALU = @SexType) + N' ' + @FrstName + N' ' + @LastName + N' ' + @MsgbText;
            
            IF @SendInfo = '002'
            BEGIN            
               SELECT @MesgInfo =                       
                      N'اطلاعات بیمه شما به شرح زیر میباشد' + CHAR(10) +                       
                      N'تاریخ ثبت بیمه ' + dbo.GET_MTOS_U(r.SAVE_DATE) + CHAR(10) + 
                      N'تاریخ اعتبار بیمه ' + dbo.GET_MTOS_U(fp.INSR_DATE) + CHAR(10) +
                      N'صورتحساب ' + CHAR(10) + 
                      N'مبلغ بیمه ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, p.SUM_EXPN_PRIC + p.SUM_EXPN_EXTR_PRCT), 1), '.00', '') + N' ' + @AmntTypeDesc + CHAR(10) +
                      N'مبلغ پرداختی ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, p.SUM_RCPT_EXPN_PRIC), 1), '.00', '') + N' ' + @AmntTypeDesc + CHAR(10) 
                 FROM dbo.Request r,
                      dbo.Request_Row rr,
                      dbo.Fighter_Public fp,
                      dbo.Payment p
                WHERE r.RQID = rr.RQST_RQID
                  AND fp.RQRO_RQST_RQID = r.RQID
                  AND rr.FIGH_FILE_NO = fp.FIGH_FILE_NO
                  AND fp.RECT_CODE = '004'                  
                  AND r.RQID = p.RQST_RQID
                  AND r.RQID = @Rqid;
                                   
               SET @MsgbText = @MsgbText + CHAR(10) + @MesgInfo;
            END;

            IF @InsrCnamStat = '002'
               SET @MsgbText = @MsgbText + N' ' + @ClubName;
            
            DECLARE @XMsg XML;
            SELECT @XMsg = (
               SELECT 5 AS '@subsys',
                      @LineType AS '@linetype',
                      (
                        SELECT @CellPhon AS '@phonnumb',
                               (
                                   SELECT '011' AS '@type' 
                                          ,@Rqid AS '@rfid'
                                          ,@MsgbText
                                      FOR XML PATH('Message'), TYPE 
                               ) 
                           FOR XML PATH('Contact'), TYPE
                      )
                 FOR XML PATH('Contacts'), ROOT('Process')                            
            );
            EXEC dbo.MSG_SEND_P @X = @XMsg -- xml
            
            -- ارسال پیامک به مادر
            IF @MomCellPhon IS NOT NULL
            BEGIN
               SELECT @XMsg = (
                  SELECT 5 AS '@subsys',
                         @LineType AS '@linetype',
                         (
                           SELECT @MomCellPhon AS '@phonnumb',
                                  (
                                      SELECT '011' AS '@type' 
                                             ,@Rqid AS '@rfid'
                                             ,N'مادر ' + CASE @SexType WHEN '001' THEN (N' آقا ' + @FrstName) ELSE (@FrstName + N' خانم ') END + CHAR(10) + N' اطلاعات بیمه فرزند دلبند شما با موفقیت در سامانه ثبت گردید. ' + CHAR(10) + N'با آرزوی بهترین ها برای شما خانواده ' + @LastName + N' عزیز ' + CHAR(10) + CASE @SendInfo WHEN '002' THEN @MesgInfo ELSE N' ' END + CASE @InsrCnamStat WHEN '002' THEN @ClubName ELSE N'' END 
                                         FOR XML PATH('Message'), TYPE 
                                  ) 
                              FOR XML PATH('Contact'), TYPE
                         )
                    FOR XML PATH('Contacts'), ROOT('Process')                            
               );
               EXEC dbo.MSG_SEND_P @X = @XMsg -- xml
            END
            
            -- ارسال پیامک به پدر
            IF @DadCellPhon IS NOT NULL
            BEGIN
               SELECT @XMsg = (
                  SELECT 5 AS '@subsys',
                         @LineType AS '@linetype',
                         (
                           SELECT @DadCellPhon AS '@phonnumb',
                                  (
                                      SELECT '011' AS '@type' 
                                             ,@Rqid AS '@rfid'
                                             ,N'پدر ' + CASE @SexType WHEN '001' THEN (N' آقا ' + @FrstName) ELSE (@FrstName + N' خانم ') END + CHAR(10) + N' اطلاعات بیمه فرزند دلبند شما با موفقیت در سامانه ثبت گردید. ' + CHAR(10) + N'با آرزوی بهترین ها برای شما خانواده ' + @LastName + N' عزیز ' + CHAR(10) + CASE @SendInfo WHEN '002' THEN @MesgInfo ELSE N' ' END + CASE @InsrCnamStat WHEN '002' THEN @ClubName ELSE N'' END 
                                         FOR XML PATH('Message'), TYPE 
                                  ) 
                              FOR XML PATH('Contact'), TYPE
                         )
                    FOR XML PATH('Contacts'), ROOT('Process')                            
               );
               EXEC dbo.MSG_SEND_P @X = @XMsg -- xml
            END;
            
            -- ارسال پیامک هشدار جهت تمدید مجدد
            -- بررسی اینکه پیامک هشدار فعال میباشد یا خیر
            IF EXISTS(SELECT * FROM dbo.Message_Broadcast WHERE MSGB_TYPE = '012' AND STAT = '002' AND MIN_NUMB_DAY_RMND != 0)
            BEGIN
               SELECT @MsgbStat = STAT
                     ,@MsgbText = MSGB_TEXT
                     ,@ClubName = CLUB_NAME
                     ,@InsrCnamStat = INSR_CNAM_STAT
                     ,@InsrFnamStat = INSR_FNAM_STAT
                     ,@MinNumbDayRmnd = MIN_NUMB_DAY_RMND
                 FROM dbo.Message_Broadcast
                WHERE MSGB_TYPE = '012';
               
               IF @MsgbStat = '002' 
               BEGIN
                  IF @InsrFnamStat = '002'
                     SET @MsgbText = (SELECT DOMN_DESC FROM dbo.[D$SXDC] WHERE VALU = @SexType) + N' ' + @FrstName + N' ' + @LastName + N' ' + @MsgbText;
                  
                  IF @InsrCnamStat = '002'
                     SET @MsgbText = @MsgbText + N' ' + @ClubName;
                     
                  --DECLARE @XMsg XML;
                  SELECT @XMsg = (
                     SELECT 5 AS '@subsys',
                            '001' AS '@linetype',
                            (
                              SELECT @CellPhon AS '@phonnumb',
                                     (
                                         SELECT '012' AS '@type' 
                                                ,@Rqid AS '@rfid'
                                                ,DATEADD(DAY, @MinNumbDayRmnd * -1, @InsrDate ) AS '@actndate'
                                                ,@MsgbText
                                            FOR XML PATH('Message'), TYPE 
                                     ) 
                                 FOR XML PATH('Contact'), TYPE
                            ),
                            (
                              SELECT @DadCellPhon AS '@phonnumb',
                                     (
                                       SELECT '012' AS '@type' 
                                              ,@Rqid AS '@rfid'
                                              ,DATEADD(DAY, @MinNumbDayRmnd * -1, @InsrDate ) AS '@actndate'
                                              ,N'پدر ' + CASE @SexType WHEN '001' THEN (N' آقا ' + @FrstName) ELSE (@FrstName + N' خانم ') END + CHAR(10) + N' یبمه فرزند شما روبه اتمام می باشد لطفا جهت تمدید بیمه اقدام فرمایید ' + CHAR(10) + N'با آرزوی بهترین ها برای شما خانواده ' + @LastName + N' عزیز ' + CHAR(10) + N' تاریخ اتمام بیمه ' + dbo.GET_MTOS_U(@InsrDate) + CHAR(10) + CASE @InsrCnamStat WHEN '002' THEN @ClubName ELSE N'' END 
                                          FOR XML PATH('Message'), TYPE 
                                     ) 
                                 FOR XML PATH('Contact'), TYPE
                            ),
                            (
                              SELECT @MomCellPhon AS '@phonnumb',
                                     (
                                         SELECT '012' AS '@type' 
                                                ,@Rqid AS '@rfid'
                                                ,DATEADD(DAY, @MinNumbDayRmnd * -1, @InsrDate ) AS '@actndate'
                                                ,N'مادر ' + CASE @SexType WHEN '001' THEN (N' آقا ' + @FrstName) ELSE (@FrstName + N' خانم ') END + CHAR(10) + N' بیمه فرزند شما روبه اتمام می باشد لطفا جهت تمدید بیمه اقدام فرمایید ' + CHAR(10) + N'با آرزوی بهترین ها برای شما خانواده ' + @LastName + N' عزیز ' + CHAR(10) + N' تاریخ اتمام بیمه ' + dbo.GET_MTOS_U(@InsrDate) + CHAR(10) + CASE @InsrCnamStat WHEN '002' THEN @ClubName ELSE N'' END 
                                            FOR XML PATH('Message'), TYPE 
                                     ) 
                                 FOR XML PATH('Contact'), TYPE
                            )
                       FOR XML PATH('Contacts'), ROOT('Process')                            
                  );
                  EXEC dbo.MSG_SEND_P @X = @XMsg -- xml
               END;
            END
            
         END;
      END;

      COMMIT TRAN T1;
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
      ROLLBACK TRAN T1;
   END CATCH;   
END
GO
