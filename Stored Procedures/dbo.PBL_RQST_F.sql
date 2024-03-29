SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[PBL_RQST_F]
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
   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>98</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 98 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END

   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>99</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 99 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>100</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 100 سطوح امینتی', -- Message text.
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
	           @RqstDesc NVARCHAR(1000),
	           @RqtpCode VARCHAR(3),
	           @RqttCode VARCHAR(3),
	           @RegnCode VARCHAR(3),
	           @PrvnCode VARCHAR(3);
      DECLARE @FileNo BIGINT;   	
      
	   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT')
	         ,@RqstRqid = @X.query('//Request').value('(Request/@rqstrqid)[1]', 'BIGINT')
	         ,@RqstDesc = @X.query('//Request').value('(Request/@rqstdesc)[1]', 'NVARCHAR(1000)')
	         ,@RqtpCode = @X.query('//Request').value('(Request/@rqtpcode)[1]', 'VARCHAR(3)')
	         ,@RqttCode = @X.query('//Request').value('(Request/@rqttcode)[1]', 'VARCHAR(3)')
	         ,@RegnCode = @X.query('//Request').value('(Request/@regncode)[1]', 'VARCHAR(3)')
	         ,@PrvnCode = @X.query('//Request').value('(Request/@prvncode)[1]', 'VARCHAR(3)')
	         ,@FileNo   = @X.query('//Request_Row').value('(Request_Row/@fileno)[1]', 'BIGINT');
      
      IF @FileNo = 0 OR @FileNo IS NULL BEGIN RAISERROR(N'شماره پرونده برای هنرجو وارد نشده', 16, 1); RETURN; END
      IF LEN(@RqttCode) <> 3 BEGIN RAISERROR(N'نوع متقاضی برای درخواست وارد نشده', 16, 1); RETURN; END      
      IF @RqstRqid = 0 SET @RqstRqid = NULL;
      
      SELECT @RegnCode = Regn_Code, @PrvnCode = Regn_Prvn_Code 
        FROM Fighter
       WHERE FILE_NO = @FileNo;
      
      /* ثبت شماره درخواست */
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
      UPDATE dbo.Request
         SET RQST_DESC = @RqstDesc
       WHERE RQID = @Rqid;
/*      ELSE
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
*/
      --SELECT @FileNo = @X.query('//Fighter').value('(Fighter/@fileno)[1]', 'BIGINT');

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
      
      IF EXISTS(
         SELECT *
           FROM Fighter_Public
          WHERE RQRO_RQST_RQID = @Rqid
            AND FIGH_FILE_NO = @FileNo
      )
      BEGIN
       SELECT @DiseCode = r.query('Fighter_Public/Dise_Code').value('.', 'BIGINT')
             ,@ClubCode = r.query('Fighter_Public/Club_Code').value('.', 'BIGINT')
             ,@FrstName = r.query('Fighter_Public/Frst_Name').value('.', 'NVARCHAR(250)')
             ,@LastName = r.query('Fighter_Public/Last_Name').value('.', 'NVARCHAR(250)')
             ,@FathName = r.query('Fighter_Public/Fath_Name').value('.', 'NVARCHAR(250)')
             ,@SexType  = r.query('Fighter_Public/Sex_Type').value('.', 'VARCHAR(3)')
             ,@NatlCode = r.query('Fighter_Public/Natl_Code').value('.', 'VARCHAR(10)')
             ,@BrthDate = r.query('Fighter_Public/Brth_Date').value('.', 'Date')
             ,@CellPhon = r.query('Fighter_Public/Cell_Phon').value('.', 'VARCHAR(11)')
             ,@TellPhon = r.query('Fighter_Public/Tell_Phon').value('.', 'VARCHAR(11)')
             ,@CochDeg  = r.query('Fighter_Public/Coch_Deg').value('.', 'VARCHAR(3)')
             ,@GudgDeg  = r.query('Fighter_Public/Gudg_Deg').value('.', 'VARCHAR(3)')
             ,@GlobCode = r.query('Fighter_Public/Glob_Code').value('.', 'VARCHAR(20)')
             ,@Type     = r.query('Fighter_Public/Type').value('.', 'VARCHAR(3)')
             ,@PostAdrs = r.query('Fighter_Public/Post_Adrs').value('.', 'NVARCHAR(1000)')
             ,@EmalAdrs = r.query('Fighter_Public/Emal_Adrs').value('.', 'VARCHAR(250)')
             ,@InsrNumb = r.query('Fighter_Public/Insr_Numb').value('.', 'VARCHAR(10)')
             ,@InsrDate = r.query('Fighter_Public/Insr_Date').value('.', 'DATE')
             ,@EducDeg  = r.query('Fighter_Public/Educ_Deg').value('.', 'VARCHAR(3)')
             ,@CochFileNo = r.query('Fighter_Public/Coch_File_No').value('.', 'BIGINT')
             ,@CochCrtfDate = r.query('Fighter_Public/Coch_Crtf_Date').value('.', 'DATE')
             ,@CbmtCode = r.query('Fighter_Public/Cbmt_Code').value('.', 'BIGINT')
             ,@DayType = r.query('Fighter_Public/Day_Type').value('.', 'VARCHAR(3)')
             ,@AttnTime = r.query('Fighter_Public/Attn_Time').value('.', 'TIME(7)')
             ,@CalcExpnType = r.query('Fighter_Public/Calc_Expn_Type').value('.', 'VARCHAR(3)')
             ,@BlodGrop = r.query('Fighter_Public/Blod_Grop').value('.', 'VARCHAR(3)')
             ,@FngrPrnt = r.query('Fighter_Public/Fngr_Prnt').value('.', 'VARCHAR(20)')
             ,@SuntBuntDeptOrgnCode = r.query('Fighter_Public/Sunt_Bunt_Dept_Orgn_Code').value('.', 'VARCHAR(2)')
             ,@SuntBuntDeptCode = r.query('Fighter_Public/Sunt_Bunt_Dept_Code').value('.', 'VARCHAR(2)')
             ,@SuntBuntCode = r.query('Fighter_Public/Sunt_Bunt_Code').value('.', 'VARCHAR(2)')
             ,@SuntCode = r.query('Fighter_Public/Sunt_Code').value('.', 'VARCHAR(4)')
             ,@CordX = r.query('Fighter_Public/Cord_X').value('.', 'REAL')
             ,@CordY = r.query('Fighter_Public/Cord_Y').value('.', 'REAL')
             ,@MostDebtClng = r.query('Fighter_Public/Most_Debt_Clng').value('.', 'BIGINT')
             ,@ServNo = r.query('Fighter_Public/Serv_No').value('.', 'NVARCHAR(50)')
             ,@BrthPlac = r.query('Fighter_Public/Brth_Plac').value('.', 'NVARCHAR(100)')
             ,@IssuPlac = r.query('Fighter_Public/Issu_Plac').value('.', 'NVARCHAR(100)')
             ,@FathWork = r.query('Fighter_Public/Fath_Work').value('.', 'NVARCHAR(150)')
             ,@HistDesc = r.query('Fighter_Public/Hist_Desc').value('.', 'NVARCHAR(500)')
             --,@IntrFileNo = r.query('Fighter_Public/Intr_File_No').value('.', 'BIGINT')             
             --,@CntrCode = r.query('Fighter_Public/Cntr_Code').value('.', 'BIGINT')             
             ,@DpstAcntSlryBank = r.query('Fighter_Public/Dpst_Acnt_Slry_Bank').value('.', 'NVARCHAR(50)')             
             ,@DpstAcntSlry = r.query('Fighter_Public/Dpst_Acnt_Slry').value('.', 'VARCHAR(50)')             
             ,@ChatId = r.query('Fighter_Public/Chat_Id').value('.', 'BIGINT')             
             ,@MomCellPhon = r.query('Fighter_Public/Mom_Cell_Phon').value('.', 'VARCHAR(11)')
             ,@MomTellPhon = r.query('Fighter_Public/Mom_Tell_Phon').value('.', 'VARCHAR(11)')             
             ,@MomChatId = r.query('Fighter_Public/Mom_Chat_Id').value('.', 'BIGINT')             
             ,@DadCellPhon = r.query('Fighter_Public/Dad_Cell_Phon').value('.', 'VARCHAR(11)')             
             ,@DadTellPhon = r.query('Fighter_Public/Dad_Tell_Phon').value('.', 'VARCHAR(11)')             
             ,@DadChatId = r.query('Fighter_Public/Dad_Chat_Id').value('.', 'BIGINT')
             ,@IDTYNUMB = r.query('Fighter_Public/Idty_Numb').value('.', 'VARCHAR(20)')
             --,@WATRFABRNUMB = r.query('Fighter_Public/Watr_Fabr_Numb').value('.', 'NVARCHAR(30)')
             --,@GASFABRNUMB = r.query('Fighter_Public/Gas_Fabr_Numb').value('.', 'NVARCHAR(30)')
             --,@POWRFABRNUMB = r.query('Fighter_Public/Powr_Fabr_Numb').value('.', 'NVARCHAR(30)')
             --,@BULDAREA = r.query('Fighter_Public/Buld_Area').value('.', 'INT')
             --,@CHLDFMLYNUMB = r.query('Fighter_Public/Chld_Fmly_Numb').value('.', 'SMALLINT')
             --,@DPENFMLYNUMB = r.query('Fighter_Public/Dpen_Fmly_Numb').value('.', 'SMALLINT')
             --,@FMLYNUMB = r.query('Fighter_Public/Fmly_Numb').value('.', 'SMALLINT')
             --,@HIREDATE = r.query('Fighter_Public/Hire_Date').value('.', 'DATETIME')
             --,@HIRETYPE = r.query('Fighter_Public/Hire_Type').value('.', 'VARCHAR(3)')
             --,@HIREPLACCODE = r.query('Fighter_Public/Hire_Plac_Code').value('.', 'BIGINT')
             --,@HOMETYPE = r.query('Fighter_Public/Home_Type').value('.', 'VARCHAR(3)')
             --,@HIRECELLPHON = r.query('Fighter_Public/Hire_Cell_Phon').value('.', 'VARCHAR(11)')
             --,@HIRETELLPHON = r.query('Fighter_Public/Hire_Tell_Phon').value('.', 'VARCHAR(11)')
             --,@SALRPLACCODE = r.query('Fighter_Public/Salr_Plac_Code').value('.', 'BIGINT')
             --,@UNITBLOKCNDOCODE = r.query('Fighter_Public/Unit_Blok_Cndo_Code').value('.', 'VARCHAR(3)')
             --,@UNITBLOKCODE = r.query('Fighter_Public/Unit_Blok_Code').value('.', 'VARCHAR(3)')
             --,@UNITCODE = r.query('Fighter_Public/Unit_Code').value('.', 'VARCHAR(3)')
             --,@PUNTBLOKCNDOCODE = r.query('Fighter_Public/Punt_Blok_Cndo_Code').value('.', 'VARCHAR(3)')
             --,@PUNTBLOKCODE = r.query('Fighter_Public/Punt_Blok_Code').value('.', 'VARCHAR(3)')
             --,@PUNTCODE = r.query('Fighter_Public/Punt_Code').value('.', 'VARCHAR(3)')
             --,@PHASNUMB = r.query('Fighter_Public/Phas_Numb').value('.', 'SMALLINT')
             --,@HIREDEGR = r.query('Fighter_Public/Hire_Degr').value('.', 'VARCHAR(3)')
             --,@HIREPLACDEGR = r.query('Fighter_Public/Hire_Plac_Degr').value('.', 'VARCHAR(3)')
             --,@SCORNUMB = r.query('Fighter_Public/Scor_Numb').value('.', 'SMALLINT')
             --,@HOMEREGNPRVNCNTYCODE = r.query('Fighter_Public/Home_Regn_Prvn_Cnty_Code').value('.', 'VARCHAR(3)')
             --,@HOMEREGNPRVNCODE = r.query('Fighter_Public/Home_Regn_Prvn_Code').value('.', 'VARCHAR(3)')
             --,@HOMEREGNCODE = r.query('Fighter_Public/Home_Regn_Code').value('.', 'VARCHAR(3)')
             --,@HOMEPOSTADRS = r.query('Fighter_Public/Home_Post_Adrs').value('.', 'NVARCHAR(1000)')
             --,@HOMECORDX = r.query('Fighter_Public/Home_Cord_X').value('.', 'FLOAT')
             --,@HOMECORDY = r.query('Fighter_Public/Home_Cord_Y').value('.', 'FLOAT')
             --,@HOMEZIPCODE = r.query('Fighter_Public/Home_Zip_Code').value('.', 'VARCHAR(10)')
             ,@ZIPCODE = r.query('Fighter_Public/Zip_Code').value('.', 'VARCHAR(10)')
             --,@RISKCODE = r.query('Fighter_Public/Risk_Code').value('.', 'VARCHAR(20)')
             --,@RISKNUMB = r.query('Fighter_Public/Risk_Numb').value('.', 'SMALLINT')
             --,@WARDAYNUMB = r.query('Fighter_Public/War_Day_Numb').value('.', 'INT')
             --,@CPTVDAYNUMB = r.query('Fighter_Public/Cptv_Day_Numb').value('.', 'INT')
             --,@MRIDTYPE = r.query('Fighter_Public/Mrid_Type').value('.', 'VARCHAR(3)')
             --,@JOBTITLCODE = r.query('Fighter_Public/Job_Titl_Code').value('.', 'BIGINT')
             ,@CMNT = r.query('Fighter_Public/Cmnt').value('.', 'NVARCHAR(4000)')
             ,@Password = r.query('Fighter_Public/Pass_Word').value('.', 'VARCHAR(250)')
             ,@RefCode = r.query('Fighter_Public/Ref_Code').value('.', 'BIGINT')
         FROM @X.nodes('//Request_Row')Rr(r)
        WHERE r.query('.').value('(Request_Row/@fileno)[1]', 'BIGINT') = @FileNo;
         
         -- Begin Check Validate
      IF LEN(@FrstName)        = 0 RAISERROR (N'برای فیلد "نام" اطلاعات وارد نشده' , 16, 1);
		IF LEN(@LastName)        = 0 RAISERROR (N'برای فیلد "نام خانوداگی" اطلاعات وارد نشده' , 16, 1);
		 --IF LEN(@FathName)        = 0 RAISERROR (N'برای فیلد "نام پدر" درخواست اطلاعات وارد نشده' , 16, 1);
		 --IF LEN(@SexType)         = 0 SET @SexType = '001';--RAISERROR (N'برای فیلد "جنسیت" درخواست اطلاعات وارد نشده' , 16, 1);
		IF LEN(@SexType)         = 0 RAISERROR (N'برای فیلد "جنسیت" اطلاعات وارد نشده' , 16, 1);
		--IF LEN(@CellPhon)        = 0 RAISERROR (N'برای فیلد "موبایل" اطلاعات وارد نشده' , 16, 1);
      IF @BrthDate = '1900-01-01' RAISERROR (N'برای فیلد "تاریخ تولد" اطلاعات وارد نشده' , 16, 1);
      IF ISNULL(@DiseCode, 0) = 0 SET @DiseCode = NULL;
         --IF ISNULL(@MtodCode, 0) = 0 RAISERROR (N'برای فیلد "سبک" درخواست ،اطلاعات وارد نشده' , 16, 1);
         --IF ISNULL(@CtgyCode, 0) = 0 RAISERROR (N'برای فیلد "رده کمربندی" درخواست ،اطلاعات وارد نشده' , 16, 1);
         --IF ISNULL(@ClubCode, 0) = 0 RAISERROR (N'برای فیلد "باشگاه" درخواست ،اطلاعات وارد نشده' , 16, 1);
         --IF ISNULL(@CbmtCode , 0) = 0 AND @Type IN ('001', '004') RAISERROR(N'ساعت کلاسی برای هنرجو وارد نشده', 16, 1);
      IF LEN(@Type)           = 0 RAISERROR (N'برای فیلد "نوع هنرجو" درخواست ،اطلاعات وارد نشده' , 16, 1);         
      
      -- 1400/04/25 * چک کردن اینکه شماره کد ملی باید وارد بشود یا نه
      IF EXISTS(SELECT TOP 1 * FROM dbo.Settings s, dbo.V#UCFGA cm WHERE s.CLUB_CODE = cm.CLUB_CODE AND ISNULL(s.INPT_CELL_PHON_STAT, '002') = '002')
      IF LEN(@CellPhon)        = 0 RAISERROR (N'برای فیلد "موبایل" اطلاعات وارد نشده' , 16, 1);
      IF EXISTS(SELECT TOP 1 * FROM dbo.Settings s, dbo.V#UCFGA cm WHERE s.CLUB_CODE = cm.CLUB_CODE AND ISNULL(s.INPT_NATL_CODE_STAT, '002') = '002')
		IF LEN(@NatlCode)        = 0 RAISERROR (N'برای فیلد "کد ملی" اطلاعات وارد نشده' , 16, 1);
      
         SET @SuntBuntDeptOrgnCode = CASE LEN(@SuntBuntDeptOrgnCode) WHEN 2 THEN @SuntBuntDeptOrgnCode ELSE '00'   END;
         SET @SuntBuntDeptCode     = CASE LEN(@SuntBuntDeptCode)     WHEN 2 THEN @SuntBuntDeptCode     ELSE '00'   END;
         SET @SuntBuntCode         = CASE LEN(@SuntBuntCode)         WHEN 2 THEN @SuntBuntCode         ELSE '00'   END;
         SET @SuntCode             = CASE LEN(@SuntCode)             WHEN 4 THEN @SuntCode             ELSE '0000' END;

	      -- مربی یا نماینده
         IF @Type IN ('002', '003')
         BEGIN
		     --IF ISNULL(@MtodCode, 0)  = 0 RAISERROR (N'برای فیلد "سبک" درخواست ،اطلاعات وارد نشده' , 16, 1);
		     --IF ISNULL(@CtgyCode, 0) = 0 RAISERROR (N'برای فیلد "رده / رسته" درخواست ،اطلاعات وارد نشده' , 16, 1);
		     --*IF ISNULL(@CochDeg, 0)   = 0 RAISERROR (N'برای فیلد "درجه مربیگری" درخواست ،اطلاعات وارد نشده' , 16, 1);
		     --*IF @CochCrtfDate IN ('1900-01-01', '0001-01-01') RAISERROR (N'برای فیلد "تاریخ مربیگری" درخواست ،اطلاعات وارد نشده' , 16, 1);
		     --*IF LEN(@EducDeg)         = 0 RAISERROR (N'برای فیلد "مدرک تحصیلی" درخواست ،اطلاعات وارد نشده' , 16, 1);
		     IF LEN(@CalcExpnType)    = 0 SET @CalcExpnType = '001' --RAISERROR (N'برای فیلد "محاسبه دستمزد مربی" درخواست ،اطلاعات وارد نشده' , 16, 1);
         END
         
         -- هنرجو مهمان بیمه دار
         IF @Type IN ('006')
         BEGIN
            IF LEN(@InsrNumb) = 0 RAISERROR (N'برای فیلد "شماره بیمه" درخواست ،اطلاعات وارد نشده' , 16, 1);
            IF @InsrDate IN ('1900-01-01', '0001-01-01') RAISERROR (N'برای فیلد "تاریخ بیمه" درخواست ،اطلاعات وارد نشده' , 16, 1);
         END
         -- اعضای جلسات ترکیبی
         --IF @Type IN ('009')
         --BEGIN
         --   SET @CbmtCode = NULL;
         --   SELECT @ClubCode = CLUB_CODE_DNRM
         --     FROM dbo.Fighter
         --    WHERE FILE_NO = @FileNo;
         --END
         
         -- هنرجو یا مهمان
         --IF @Type IN ('001', '005', '006', '008')
         --BEGIN
         --   SELECT @MtodCode = MTOD_CODE
         --         ,@ClubCode = CLUB_CODE
         --         ,@CochFileNo = COCH_FILE_NO
         --         ,@DayType = DAY_TYPE
         --         ,@AttnTime = STRT_TIME
         --     FROM Club_Method
         --   WHERE CODE = @CbmtCode;
         --   -- 1395/03/14 * اگر بخواهد از طریق مشخصات عمومی سبک هنرجو را عوض کند اینجا با پیام خطا مواجه میشود            
         --   IF NOT EXISTS (
         --      SELECT *
         --        FROM dbo.Fighter
         --       WHERE FILE_NO = @FileNo                  
         --         AND (MTOD_CODE_DNRM IS NULL OR MTOD_CODE_DNRM = @MtodCode)
         --   )
         --   BEGIN
         --      RAISERROR (N'ساعت کلاسی وارده شده متناسب با سبک هنرجو نمی باشد، لطفا اصلاح کنید' , 16, 1);
         --   END
         --END
         -- هنرجو یا مهمان
         IF @Type IN ('001', '005', '006', '008')
         BEGIN
            SELECT @MtodCode = MTOD_CODE
                  ,@CtgyCode = CTGY_CODE
                  ,@CbmtCode = CBMT_CODE
                  ,@CochFileNo = COCH_FILE_NO
                  ,@ClubCode = CLUB_CODE
              FROM dbo.Fighter_Public
             WHERE RQRO_RQST_RQID = @Rqid
               AND FIGH_FILE_NO = @FileNo;
         END
         -- مربی یا نماینده
         ELSE IF @Type IN ('002', '003')
            SELECT @ClubCode = NULL
                  ,@DayType = NULL
                  ,@AttnTime = NULL;                  
            
         -- اگر باشگاه مشخص نباشد
         IF ISNULL(@ClubCode, 0) = 0 AND (SELECT COUNT(CODE) FROM Club) >= 1
            SELECT TOP 1 @ClubCode = Code
              FROM Club;      
         
         -- اگر رسته هنرجو مشخص نباشد
         /*IF ISNULL(@CtgyCode, 0) = 0
            SELECT @CtgyCode = Code
              FROM Category_Belt
             WHERE MTOD_CODE = @MtodCode
               AND ORDR = 0;      
         */
         SELECT @ActvTag = ACTV_TAG_DNRM FROM Fighter WHERE FILE_NO = @FileNo;
         
         IF LEN(@FngrPrnt) <> 0 AND EXISTS(SELECT * FROM dbo.Fighter WHERE FNGR_PRNT_DNRM = @FngrPrnt AND FILE_NO <> @FileNo )
         BEGIN
            RAISERROR (N'برای فیلد کد اثر انگشت قبلا توسط هنرجوی دیگری رزرو شده است. لطفا اصلاح کنید' , 16, 1);
         END
         
   		-- 1400/04/25 * چک کردن اینکه شماره کد ملی باید وارد بشود یا نه
		   IF EXISTS(SELECT * FROM dbo.Settings s, dbo.Club_Method cm WHERE s.CLUB_CODE = cm.CLUB_CODE AND cm.CODE = @CbmtCode AND ISNULL(s.INPT_CELL_PHON_STAT, '002') = '002')
		      IF LEN(@CellPhon)        = 0 RAISERROR (N'برای فیلد "موبایل" اطلاعات وارد نشده' , 16, 1);
		   IF EXISTS(SELECT * FROM dbo.Settings s, dbo.Club_Method cm WHERE s.CLUB_CODE = cm.CLUB_CODE AND cm.CODE = @CbmtCode AND ISNULL(s.INPT_NATL_CODE_STAT, '002') = '002')
			   IF LEN(@NatlCode)        = 0 RAISERROR (N'برای فیلد "کد ملی" اطلاعات وارد نشده' , 16, 1);

         -- End   Check Validate
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
             ,@ActvTag      = ISNULL(p.ACTV_TAG, '101')
             ,@BlodGrop     = p.BLOD_GROP
             ,@FngrPrnt     = p.FNGR_PRNT
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
             ,@IdtyNumb = p.IDTY_NUMB
             ,@ZipCode = p.ZIP_CODE
             ,@Cmnt = p.CMNT
             --,@UnitBlokCndoCode = P.UNIT_BLOK_CNDO_CODE
             --,@UnitBlokCode = P.UNIT_BLOK_CODE
             --,@UnitCode = P.UNIT_CODE
             ,@Password = P.PASS_WORD
             ,@RefCode = P.REF_CODE
         FROM Fighter F, Fighter_Public P
        WHERE F.FILE_NO = @FileNo
          AND F.FILE_NO = P.FIGH_FILE_NO
          AND F.FGPB_RWNO_DNRM = P.RWNO
          AND P.RECT_CODE = '004';
      END
      
      SELECT @MtodCode = MTOD_CODE_DNRM
            ,@CtgyCode = CTGY_CODE_DNRM
        FROM Fighter
       WHERE FILE_NO = @FileNo;
      
      /* ثبت اطلاعات عمومی پرونده */
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


          
	   -- اگر در ثبت موقت باشیم و برای نوع درخواست و متقاضی آیین نامه هزینه داری داشته باشیم درخواست را به فرم اعلام هزینه ارسال میکنیم            
      /*IF EXISTS(
         SELECT *
           FROM Request_Row Rr, Fighter F
          WHERE Rr.FIGH_FILE_NO = F.FILE_NO
            AND Rr.RQST_RQID = @Rqid
            AND EXISTS(
               SELECT *
                 FROM dbo.VF$All_Expense_Detail(@PrvnCode, @RegnCode, NULL, @RqtpCode, @RqttCode, NULL, NULL, F.Mtod_Code_Dnrm , F.Ctgy_Code_Dnrm)
            )
      )
         UPDATE Request
         SET SEND_EXPN = '002'
         WHERE RQID = @Rqid;
      ELSE
         UPDATE Request
         SET SEND_EXPN = '001'
         WHERE RQID = @Rqid;   
      */
      
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
