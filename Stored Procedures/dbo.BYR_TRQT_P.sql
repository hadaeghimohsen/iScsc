SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[BYR_TRQT_P]
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
             ,@IssuPlac NVARCHAR(100)
             ,@FathWork NVARCHAR(150)
             ,@HistDesc NVARCHAR(500)
             --,@IntrFileNo BIGINT 
             --,@CntrCode BIGINT
             ,@ChatId BIGINT
             ,@MomCellPhon VARCHAR(11)
             ,@MomTellPhon VARCHAR(11)
             ,@MomChatId BIGINT
             ,@DadCellPhon VARCHAR(11)
             ,@DadTellPhon VARCHAR(11)
             ,@DadChatId BIGINT
             ,@StrtDate DATE
             ,@EndDate DATE
             ,@NumbMontOfer INT
             ,@NumbOfAttnMont INT
             ,@NumbOfAttnWeek INT
             ,@AttnDayType VARCHAR(3);
             
      SELECT @DiseCode = @X.query('//Dise_Code').value('.', 'BIGINT')
            ,@MtodCode = @X.query('//Mtod_Code').value('.', 'BIGINT')
            ,@CtgyCode = @X.query('//Ctgy_Code').value('.', 'BIGINT')
            ,@ClubCode = @X.query('//Club_Code').value('.', 'BIGINT')
            ,@FrstName = @X.query('//Frst_Name').value('.', 'NVARCHAR(250)')
            ,@LastName = @X.query('//Last_Name').value('.', 'NVARCHAR(250)')
            ,@FathName = @X.query('//Fath_Name').value('.', 'NVARCHAR(250)')
            ,@SexType  = @X.query('//Sex_Type').value('.', 'VARCHAR(3)')
            ,@NatlCode = @X.query('//Natl_Code').value('.', 'VARCHAR(10)')
            ,@BrthDate = @X.query('//Brth_Date').value('.', 'Date')
            ,@CellPhon = @X.query('//Cell_Phon').value('.', 'VARCHAR(11)')
            ,@TellPhon = @X.query('//Tell_Phon').value('.', 'VARCHAR(11)')
            --,@CochDeg  = @X.query('//Coch_Deg').value('.', 'VARCHAR(3)')
            --,@GudgDeg  = @X.query('//Gudg_Deg').value('.', 'VARCHAR(3)')
            --,@GlobCode = @X.query('//Glob_Code').value('.', 'VARCHAR(20)')
            ,@Type     = @X.query('//Type').value('.', 'VARCHAR(3)')
            ,@PostAdrs = @X.query('//Post_Adrs').value('.', 'NVARCHAR(1000)')
            ,@EmalAdrs = @X.query('//Emal_Adrs').value('.', 'VARCHAR(250)')
            ,@InsrNumb = @X.query('//Insr_Numb').value('.', 'VARCHAR(10)')
            ,@InsrDate = @X.query('//Insr_Date').value('.', 'DATE')
            ,@EducDeg  = @X.query('//Educ_Deg').value('.', 'VARCHAR(3)')
            ,@CbmtCode = @X.query('//Cbmt_Code').value('.', 'BIGINT')
            ,@CalcExpnType = @X.query('//Calc_Expn_Type').value('.', 'VARCHAR(3)')
            ,@BlodGrop = @X.query('//Blod_Grop').value('.', 'VARCHAR(3)')
            ,@FngrPrnt = @X.query('//Fngr_Prnt').value('.', 'VARCHAR(20)')
            ,@SuntBuntDeptOrgnCode = @x.query('//Sunt_Bunt_Dept_Orgn_Code').value('.', 'VARCHAR(2)')
            ,@SuntBuntDeptCode = @x.query('//Sunt_Bunt_Dept_Code').value('.', 'VARCHAR(2)')
            ,@SuntBuntCode = @x.query('//Sunt_Bunt_Code').value('.', 'VARCHAR(2)')
            ,@SuntCode = @x.query('//Sunt_Code').value('.', 'VARCHAR(4)')
            ,@CordX = @x.query('//Cord_X').value('.', 'REAL')
            ,@CordY = @x.query('//Cord_Y').value('.', 'REAL')
            ,@MostDebtClng = @x.query('//Most_Debt_Clng').value('.', 'BIGINT')
            ,@ServNo = @x.query('//Serv_No').value('.', 'NVARCHAR(50)')
            ,@BrthPlac = @x.query('//Brth_Plac').value('.', 'NVARCHAR(100)')
            ,@IssuPlac = @x.query('//Issu_Plac').value('.', 'NVARCHAR(100)')
            ,@FathWork = @x.query('//Fath_Work').value('.', 'NVARCHAR(150)')
            ,@HistDesc = @x.query('//Hist_Desc').value('.', 'NVARCHAR(500)')
            --,@IntrFileNo = @x.query('//Intr_File_No').value('.', 'BIGINT')
            --,@CntrCode = @x.query('//Cntr_Code').value('.', 'BIGINT')
            ,@ChatId = @x.query('//Chat_Id').value('.', 'BIGINT')
            ,@StrtDate = @x.query('//Member_Ship').value('(Member_Ship/@strtdate)[1]', 'DATE')
            ,@EndDate = @x.query('//Member_Ship').value('(Member_Ship/@enddate)[1]', 'DATE')
            ,@NumbMontOfer = @x.query('//Member_Ship').value('(Member_Ship/@numbmontofer)[1]', 'INT')
            ,@NumbOfAttnMont = @x.query('//Member_Ship').value('(Member_Ship/@numbofattnmont)[1]', 'INT')
            ,@NumbOfAttnWeek = @x.query('//Member_Ship').value('(Member_Ship/@numbofattnweek)[1]', 'INT')
            ,@AttnDayType = @x.query('//Member_Ship').value('(Member_Ship/@attndaytype)[1]', 'VARCHAR(3)');
            
            --,@CochCrtfDate = @X.query('//Coch_Crtf_Date').value('.', 'DATE');
      SELECT @ActvTag = ISNULL(ACTV_TAG_DNRM, '101') FROM Fighter WHERE FILE_NO = @FileNo;
      -- Begin Check Validate
      IF LEN(@FrstName)        = 0 RAISERROR (N'برای فیلد "نام" اطلاعات وارد نشده' , 16, 1);
      IF LEN(@LastName)        = 0 RAISERROR (N'برای فیلد "نام خانوداگی" اطلاعات وارد نشده' , 16, 1);
      --IF LEN(@FathName)        = 0 RAISERROR (N'برای فیلد "نام پدر" درخواست اطلاعات وارد نشده' , 16, 1);
      IF LEN(@SexType)         = 0 SET @SexType = '001';--RAISERROR (N'برای فیلد "جنسیت" درخواست اطلاعات وارد نشده' , 16, 1);
      IF @BrthDate             = '1900-01-01' SET @BrthDate = GETDATE()--RAISERROR (N'برای فیلد "تاریخ تولد" درخواست اطلاعات وارد نشده' , 16, 1);
      IF ISNULL(@DiseCode, 0)  = 0 SET @DiseCode = NULL;
      --IF ISNULL(@MtodCode, 0)  = 0 RAISERROR (N'برای فیلد "سبک" درخواست اطلاعات وارد نشده' , 16, 1);
      --IF ISNULL(@CtgyCode, 0) = 0 RAISERROR (N'برای فیلد "رده کمربندی" درخواست اطلاعات وارد نشده' , 16, 1);
      
      IF ISNULL(@ClubCode, 0) = 0 SELECT TOP 1 @ClubCode = CLUB_CODE FROM V#UCFGA WHERE SYS_USER = UPPER(SUSER_NAME())--RAISERROR (N'برای فیلد "باشگاه" درخواست اطلاعات وارد نشده' , 16, 1);
      IF LEN(@Type)            = 0 SET @Type = '001';--RAISERROR (N'برای فیلد "نوع هنرجو" درخواست اطلاعات وارد نشده' , 16, 1);
      --IF ISNULL(@CbmtCode , 0) = 0 AND @Type IN ('001', '004') RAISERROR(N'ساعت کلاسی برای هنرجو وارد نشده', 16, 1);
      SET @SuntBuntDeptOrgnCode = CASE LEN(@SuntBuntDeptOrgnCode) WHEN 2 THEN @SuntBuntDeptOrgnCode ELSE '00'   END;
      SET @SuntBuntDeptCode     = CASE LEN(@SuntBuntDeptCode)     WHEN 2 THEN @SuntBuntDeptCode     ELSE '00'   END;
      SET @SuntBuntCode         = CASE LEN(@SuntBuntCode)         WHEN 2 THEN @SuntBuntCode         ELSE '00'   END;
      SET @SuntCode             = CASE LEN(@SuntCode)             WHEN 4 THEN @SuntCode             ELSE '0000' END;
      /*IF ISNULL(@NumbOfAttnMont, 0) > 0
      BEGIN
         IF ISNULL(@NumbOfAttnWeek, 0) = 0 SET @NumbOfAttnWeek = 3; --RAISERROR(N'برای ثبت نام جلسه ای باید تعداد روزهای حضور در هفته باید مشخص گردد', 16, 1);
         IF LEN(@AttnDayType) = 0 SET @AttnDayType = '003';--RAISERROR(N'برای ثبت نام جلسه ای باید روزهای حضور در هفته باید مشخص گردد.(زوج / فرد)', 16, 1);
      END*/
      
      IF ISNULL(@CtgyCode, 0) = 0 OR ISNULL(@MtodCode, 0) = 0
         Select TOP 1 
                @MtodCode = MTOD_CODE
               ,@CtgyCode = CODE               
           FROM dbo.Category_Belt;
      
      -- 1399/12/07 * در این قسمت این مشکل وجود دارد که با انتخاب ساعت کلاسی کد مربوط به بخش عوض میشود
      IF ISNULL(@CbmtCode, 0) = 0 AND ISNULL(@ClubCode, 0) = 0
		   Select Top 1 @CbmtCode = Code, @ClubCode = CLUB_CODE
		     FROM Club_Method;
		ELSE 
		   Select Top 1 @CbmtCode = Code, @ClubCode = CLUB_CODE
		     FROM Club_Method
		    WHERE CLUB_CODE = @ClubCode;
      
      IF LEN(@FngrPrnt) <> 0 AND EXISTS(SELECT * FROM dbo.Fighter WHERE FNGR_PRNT_DNRM = @FngrPrnt AND FILE_NO <> @FileNo )
      BEGIN
         RAISERROR (N'برای فیلد کد اثر انگشت قبلا توسط هنرجوی دیگری رزرو شده است. لطفا اصلاح کنید' , 16, 1);
      END

      -- End   Check Validate
      
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
           --,@Intr_File_No = NULL
           --,@Cntr_Code = NULL
           ,@Dpst_Acnt_Slry_Bank = NULL
           ,@Dpst_Acnt_Slry = NULL
           ,@Chat_Id = @ChatId
           ,@Mom_Cell_Phon = @MomCellPhon
           ,@Mom_Tell_Phon = @MomTellPhon
           ,@Mom_Chat_Id = @MomChatId
           ,@Dad_Cell_Phon = @DadCellPhon
           ,@Dad_Tell_Phon = @DadTellPhon
           ,@Dad_Chat_Id = @DadChatId
           ,@IDTY_NUMB = NULL
           --,@WATR_FABR_NUMB = NULL
           --,@GAS_FABR_NUMB = NULL
           --,@POWR_FABR_NUMB = NULL
           --,@BULD_AREA = NULL
           --,@CHLD_FMLY_NUMB = NULL
           --,@DPEN_FMLY_NUMB = NULL
           --,@FMLY_NUMB = NULL
           --,@HIRE_DATE = NULL
           --,@HIRE_TYPE = NULL
           --,@HIRE_PLAC_CODE = NULL
           --,@HOME_TYPE = NULL
           --,@HIRE_CELL_PHON = NULL
           --,@HIRE_TELL_PHON = NULL
           --,@SALR_PLAC_CODE = NULL
           --,@UNIT_BLOK_CNDO_CODE = NULL
           --,@UNIT_BLOK_CODE = NULL
           --,@UNIT_CODE = NULL
           --,@PUNT_BLOK_CNDO_CODE = NULL
           --,@PUNT_BLOK_CODE = NULL
           --,@PUNT_CODE = NULL
           --,@PHAS_NUMB = NULL
           --,@HIRE_DEGR = NULL
           --,@HIRE_PLAC_DEGR = NULL
           --,@SCOR_NUMB = NULL
           --,@HOME_REGN_PRVN_CNTY_CODE = NULL
           --,@HOME_REGN_PRVN_CODE = NULL
           --,@HOME_REGN_CODE = NULL
           --,@HOME_POST_ADRS = NULL
           --,@HOME_CORD_X = NULL
           --,@HOME_CORD_Y = NULL
           --,@HOME_ZIP_CODE = NULL
           ,@ZIP_CODE = NULL
           --,@RISK_CODE = NULL
           --,@RISK_NUMB = NULL
           --,@WAR_DAY_NUMB = NULL
           --,@CPTV_DAY_NUMB = NULL
           --,@MRID_TYPE = NULL
           --,@JOB_TITL_CODE = NULL
           ,@CMNT = NULL
           ,@Pass_Word = NULL;           
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
           --,@Intr_File_No = NULL
           --,@Cntr_Code = NULL
           ,@Dpst_Acnt_Slry_Bank = NULL
           ,@Dpst_Acnt_Slry = NULL
           ,@Chat_Id = @ChatId
           ,@Mom_Cell_Phon = @MomCellPhon
           ,@Mom_Tell_Phon = @MomTellPhon
           ,@Mom_Chat_Id = @MomChatId
           ,@Dad_Cell_Phon = @DadCellPhon
           ,@Dad_Tell_Phon = @DadTellPhon
           ,@Dad_Chat_Id = @DadChatId
           ,@IDTY_NUMB = NULL
           --,@WATR_FABR_NUMB = NULL
           --,@GAS_FABR_NUMB = NULL
           --,@POWR_FABR_NUMB = NULL
           --,@BULD_AREA = NULL
           --,@CHLD_FMLY_NUMB = NULL
           --,@DPEN_FMLY_NUMB = NULL
           --,@FMLY_NUMB = NULL
           --,@HIRE_DATE = NULL
           --,@HIRE_TYPE = NULL
           --,@HIRE_PLAC_CODE = NULL
           --,@HOME_TYPE = NULL
           --,@HIRE_CELL_PHON = NULL
           --,@HIRE_TELL_PHON = NULL
           --,@SALR_PLAC_CODE = NULL
           --,@UNIT_BLOK_CNDO_CODE = NULL
           --,@UNIT_BLOK_CODE = NULL
           --,@UNIT_CODE = NULL
           --,@PUNT_BLOK_CNDO_CODE = NULL
           --,@PUNT_BLOK_CODE = NULL
           --,@PUNT_CODE = NULL
           --,@PHAS_NUMB = NULL
           --,@HIRE_DEGR = NULL
           --,@HIRE_PLAC_DEGR = NULL
           --,@SCOR_NUMB = NULL
           --,@HOME_REGN_PRVN_CNTY_CODE = NULL
           --,@HOME_REGN_PRVN_CODE = NULL
           --,@HOME_REGN_CODE = NULL
           --,@HOME_POST_ADRS = NULL
           --,@HOME_CORD_X = NULL
           --,@HOME_CORD_Y = NULL
           --,@HOME_ZIP_CODE = NULL
           ,@ZIP_CODE = NULL
           --,@RISK_CODE = NULL
           --,@RISK_NUMB = NULL
           --,@WAR_DAY_NUMB = NULL
           --,@CPTV_DAY_NUMB = NULL
           --,@MRID_TYPE = NULL
           --,@JOB_TITL_CODE = NULL
           ,@CMNT = NULL
           ,@Pass_Word = NULL;
      END
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
