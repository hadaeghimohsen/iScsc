SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[PIN_RQST_F]
	@X XML
AS
BEGIN
   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>130</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 130 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END

   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>131</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 131 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>132</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 132 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END

	DECLARE @ErrorMessage NVARCHAR(MAX);
	BEGIN TRAN T1;
	BEGIN TRY
	   DECLARE @Rqid     BIGINT,
	           @RqstRqid BIGINT,
	           @RqtpCode VARCHAR(3),
	           @RqttCode VARCHAR(3),
	           @RegnCode VARCHAR(3),
	           @PrvnCode VARCHAR(3);
      DECLARE @FileNo BIGINT;   	
	   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT')
	         ,@RqstRqid = @X.query('//Request').value('(Request/@rqstrqid)[1]', 'BIGINT')
	         ,@RqtpCode = @X.query('//Request').value('(Request/@rqtpcode)[1]', 'VARCHAR(3)')
	         ,@RqttCode = @X.query('//Request').value('(Request/@rqttcode)[1]', 'VARCHAR(3)')
	         ,@RegnCode = @X.query('//Request').value('(Request/@regncode)[1]', 'VARCHAR(3)')
	         ,@PrvnCode = @X.query('//Request').value('(Request/@prvncode)[1]', 'VARCHAR(3)')
	         ,@FileNo   = @X.query('//Request_Row').value('(Request_Row/@fileno)[1]', 'BIGINT');
      
      IF @FileNo = 0 OR @FileNo IS NULL BEGIN RAISERROR(N'شماره پرونده برای هنرجو وارد نشده', 16, 1); RETURN; END
      IF LEN(@RqttCode) <> 3 BEGIN /*RAISERROR(N'نوع متقاضی برای درخواست وارد نشده', 16, 1); RETURN;*/ SET @RqttCode = '001'; END      
      IF @RqstRqid = 0 SET @RqstRqid = NULL;
      
      SELECT @RegnCode = Regn_Code, @PrvnCode = Regn_Prvn_Code 
        FROM Fighter
       WHERE FILE_NO = @FileNo;
      
      IF @Rqid IS NULL OR @Rqid = 0
      BEGIN
         EXEC dbo.INS_RQST_P
            @PrvnCode,
            @RegnCode,
            @RqstRqid,
            @RqtpCode,
            @RqttCode,
            NULL,
            NULL,
            NULL,
            @Rqid OUT;      
      END
      ELSE
      BEGIN
         UPDATE dbo.Request
            SET SSTT_MSTT_CODE = 1
               ,SSTT_CODE = 1
          WHERE RQID = @Rqid;
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
             ,@Cmnt NVARCHAR(4000);
             
      
      IF EXISTS(
         SELECT *
           FROM Fighter_Public
          WHERE RQRO_RQST_RQID = @Rqid
            AND FIGH_FILE_NO = @FileNo
      )
      BEGIN
         SELECT @InsrNumb = r.query('Fighter_Public/Insr_Numb').value('.', 'VARCHAR(10)')
               ,@InsrDate = r.query('Fighter_Public/Insr_Date').value('.', 'DATE')             
           FROM @X.nodes('//Request_Row')Rr(r)
          WHERE r.query('.').value('(Request_Row/@fileno)[1]', 'BIGINT') = @FileNo;
            
         IF LEN(@InsrNumb) = 0 RAISERROR (N'برای فیلد "شماره بیمه" درخواست ،اطلاعات وارد نشده' , 16, 1);
         IF @InsrDate IN ('1900-01-01', '0001-01-01') RAISERROR (N'برای فیلد "تاریخ بیمه" درخواست ،اطلاعات وارد نشده' , 16, 1);
         
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
             --,@InsrNumb = p.INSR_NUMB
             --,@InsrDate = p.INSR_DATE
             ,@EducDeg  = p.EDUC_DEG
             ,@CochFileNo   = p.COCH_FILE_NO
             ,@CochCrtfDate = p.COCH_CRTF_DATE
             ,@CbmtCode     = p.CBMT_CODE
             ,@DayType      = p.DAY_TYPE
             ,@AttnTime     = p.ATTN_TIME
             ,@CalcExpnType = p.CALC_EXPN_TYPE
             ,@ActvTag = ISNULL(P.ACTV_TAG, '101')
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
             ,@IntrFileNo = P.INTR_FILE_NO             
             ,@CntrCode = P.CNTR_CODE
             ,@DpstAcntSlryBank = P.DPST_ACNT_SLRY_BANK
             ,@DpstAcntSlry = P.DPST_ACNT_SLRY
             ,@ChatId = P.CHAT_ID
             ,@MomCellPhon = P.MOM_CELL_PHON
             ,@MomTellPhon = P.MOM_TELL_PHON
             ,@MomChatId = P.MOM_CHAT_ID
             ,@DadCellPhon = P.DAD_CELL_PHON
             ,@DadTellPhon = P.DAD_TELL_PHON
             ,@DadChatId = P.DAD_CHAT_ID             
         FROM Fighter F, Fighter_Public P
        WHERE F.FILE_NO = @FileNo
          AND F.FILE_NO = P.FIGH_FILE_NO
          AND F.RQST_RQID = P.RQRO_RQST_RQID          
          AND P.RECT_CODE = '001';          
      END
      ELSE
      BEGIN
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
             ,@IntrFileNo = P.INTR_FILE_NO             
             ,@CntrCode = P.CNTR_CODE
             ,@DpstAcntSlryBank = P.DPST_ACNT_SLRY_BANK
             ,@DpstAcntSlry = P.DPST_ACNT_SLRY
             ,@ChatId = P.CHAT_ID
             ,@MomCellPhon = P.MOM_CELL_PHON
             ,@MomTellPhon = P.MOM_TELL_PHON
             ,@MomChatId = P.MOM_CHAT_ID
             ,@DadCellPhon = P.DAD_CELL_PHON
             ,@DadTellPhon = P.DAD_TELL_PHON
             ,@DadChatId = P.DAD_CHAT_ID             
         FROM Fighter F, Fighter_Public P
        WHERE F.FILE_NO = @FileNo
          AND F.FILE_NO = P.FIGH_FILE_NO
          AND F.FGPB_RWNO_DNRM = P.RWNO
          AND P.RECT_CODE = '004';
        
        SELECT @InsrNumb = @NatlCode
              ,@InsrDate = DATEADD(YEAR, 1, GETDATE());
      END
      
      SELECT @MtodCode = MTOD_CODE_DNRM
            ,@CtgyCode = CTGY_CODE_DNRM
        FROM Fighter
       WHERE FILE_NO = @FileNo;
      
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
           ,@Rect_Code = '001'
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
           ,@Intr_File_No = @IntrFileNo
           ,@Cntr_Code = @CntrCode
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
           ,@Rect_Code = '001'
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
           ,@Intr_File_No = @IntrFileNo
           ,@Cntr_Code = @CntrCode
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
      
      GOTO NextFromRqrv;
      EndFetchRqrv:
      CLOSE C$RQRV;
      DEALLOCATE C$RQRV;


          
	   -- اگر در ثبت موقت باشیم و برای نوع درخواست و متقاضی آیین نامه هزینه داری داشته باشیم درخواست را به فرم اعلام هزینه ارسال میکنیم            
      IF EXISTS(
         SELECT *
           FROM Request_Row Rr, Fighter F
          WHERE Rr.FIGH_FILE_NO = F.FILE_NO
            AND Rr.RQST_RQID = @Rqid
            AND EXISTS(
               SELECT *
                 FROM dbo.VF$All_Expense_Detail(
                  @PrvnCode, 
                  @RegnCode, 
                  NULL, 
                  @RqtpCode, 
                  @RqttCode, 
                  NULL, 
                  NULL, 
                  F.Mtod_Code_Dnrm , 
                  F.Ctgy_Code_Dnrm)
            )
      )
      BEGIN
         IF NOT EXISTS(SELECT * FROM Request WHERE RQID = @Rqid AND SSTT_MSTT_CODE = 2 AND SSTT_CODE = 2)
         BEGIN
            SELECT @X = (
               SELECT @Rqid '@rqid'          
                     ,@RqtpCode '@rqtpcode'
                     ,@RqttCode '@rqttcode'
                     ,@RegnCode '@regncode'  
                     ,@PrvnCode '@prvncode'
               FOR XML PATH('Request'), ROOT('Process')
            );
            EXEC INS_SEXP_P @X;             

            UPDATE Request
               SET SEND_EXPN = '002'
                  ,SSTT_MSTT_CODE = 2
                  ,SSTT_CODE = 2
             WHERE RQID = @Rqid;
        END
      END
      ELSE
      BEGIN
         UPDATE Request
            SET SEND_EXPN = '001'
               ,SSTT_MSTT_CODE = 1
               ,SSTT_CODE = 1
          WHERE RQID = @Rqid;                
         
         DELETE Payment_Detail 
          WHERE PYMT_RQST_RQID = @Rqid;          
         DELETE dbo.Payment_Discount
          WHERE PYMT_RQST_RQID = @Rqid;
         DELETE dbo.Payment_Method
          WHERE PYMT_RQST_RQID = @Rqid;                      
         DELETE Payment
          WHERE RQST_RQID = @Rqid;            
      END  
--      END 
      
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
      --PRINT @ErrorMessage;
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T1;
   END CATCH;  
END
GO
