SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ADM_TRQT_F]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>65</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 65 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END

   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>66</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 66 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>67</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 67 سطوح امینتی', -- Message text.
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
      
      IF @RegnCode IS NULL OR @PrvnCode IS NULL 
      BEGIN
         /*SELECT TOP 1 @RegnCode = CODE
                     ,@PrvnCode = PRVN_CODE
           FROM Region;*/
         
         DECLARE @CbmtCode BIGINT
                ,@SexType  VARCHAR(3)
                ,@Type     VARCHAR(3)
                ,@MtodCode BIGINT
                ,@CtgyCode BIGINT;
         
         SELECT @CbmtCode = @X.query('//Cbmt_Code').value('.', 'BIGINT')
               ,@MtodCode = @X.query('//Mtod_Code').value('.', 'BIGINT')
               ,@CtgyCode = @X.query('//Ctgy_Code').value('.', 'BIGINT')
               ,@SexType  = @X.query('//Sex_Type').value('.', 'VARCHAR(3)')
               ,@Type     = @X.query('//Type').value('.', 'VARCHAR(3)');
               
         IF ISNULL(@CbmtCode , 0) = 0 AND @Type IN ('001', '004')
         BEGIN
            -- بدست آوردن برنامه کلاسی پیش فرض
            SELECT TOP 1 @CbmtCode = cm.CODE, @MtodCode = cm.MTOD_CODE
              FROM dbo.Club_Method cm
             WHERE cm.DFLT_STAT = '002'
               AND convert(varchar(10), GETDATE(), 108) BETWEEN convert(varchar(10), STRT_TIME, 108) AND convert(varchar(10), END_TIME, 108)
               AND cm.CLUB_CODE IN (SELECT CLUB_CODE FROM dbo.V#UCFGA WHERE Sys_User = SUSER_NAME());
            
            IF ISNULL(@CbmtCode , 0) = 0  RAISERROR(N'ساعت کلاسی برای هنرجو وارد نشده', 16, 1);
            
            -- بدست آوردن رسته پیش فرض
            SELECT TOP 1 @CtgyCode = CODE
              FROM dbo.Category_Belt
             WHERE MTOD_CODE = @MtodCode
               AND ISNULL(DFLT_STAT, '002') = '002';
         END
         IF @TYPE IN ('001', '004')
            SELECT @RegnCode = c.REGN_CODE
                  ,@PrvnCode = C.REGN_PRVN_CODE
                  ,@SexType  = CASE WHEN LEN(@SexType) != 3 THEN cm.SEX_TYPE ELSE @SexType END
              FROM dbo.Club_Method cm, Club C
             WHERE cm.Code = @CbmtCode
               AND C.CODE = Cm.CLUB_CODE;
         ELSE
            SELECT TOP 1 @RegnCode = CODE
                        ,@PrvnCode = PRVN_CODE
              FROM Region
             WHERE STAT = '002';
         
      END
      
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
             --,@MtodCode BIGINT
             --,@CtgyCode BIGINT
             ,@ClubCode BIGINT
             ,@FrstName NVARCHAR(250)
             ,@LastName NVARCHAR(250)
             ,@FathName NVARCHAR(250)
             --,@SexType  VARCHAR(3)
             ,@NatlCode VARCHAR(10)
             ,@BrthDate DATE
             ,@CellPhon VARCHAR(11)
             ,@TellPhon VARCHAR(11)
             ,@CochDeg  VARCHAR(3)
             ,@GudgDeg  VARCHAR(3)
             ,@GlobCode VARCHAR(20)
             --,@Type     VARCHAR(3)
             ,@PostAdrs NVARCHAR(1000)
             ,@EmalAdrs NVARCHAR(250)
             ,@InsrNumb VARCHAR(10)
             ,@InsrDate DATE
             ,@EducDeg VARCHAR(3)
             ,@CochFileNo BIGINT
             --,@CbmtCode BIGINT
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
             ,@IntrFileNo BIGINT             
             ,@CntrCode BIGINT
             ,@StrtDate DATE
             ,@EndDate DATE
             ,@NumbMontOfer INT
             ,@NumbOfAttnMont INT
             ,@NumbOfAttnWeek INT
             ,@AttnDayType VARCHAR(3);
             
      SELECT @DiseCode = @X.query('//Dise_Code').value('.', 'BIGINT')
            --,@MtodCode = @X.query('//Mtod_Code').value('.', 'BIGINT')
            --,@CtgyCode = @X.query('//Ctgy_Code').value('.', 'BIGINT')
            --,@ClubCode = @X.query('//Club_Code').value('.', 'BIGINT')
            ,@FrstName = @X.query('//Frst_Name').value('.', 'NVARCHAR(250)')
            ,@LastName = @X.query('//Last_Name').value('.', 'NVARCHAR(250)')
            ,@FathName = @X.query('//Fath_Name').value('.', 'NVARCHAR(250)')
            --,@SexType  = @X.query('//Sex_Type').value('.', 'VARCHAR(3)')
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
            --,@CbmtCode = @X.query('//Cbmt_Code').value('.', 'BIGINT')
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
            ,@BrthPlac = @x.query('//Brth_Palc').value('.', 'NVARCHAR(100)')
            ,@IssuPlac = @x.query('//Issu_Plac').value('.', 'NVARCHAR(100)')
            ,@FathWork = @x.query('//Fath_Work').value('.', 'NVARCHAR(150)')
            ,@HistDesc = @x.query('//Hist_Desc').value('.', 'NVARCHAR(500)')
            ,@IntrFileNo = @x.query('//Intr_File_No').value('.', 'BIGINT')
            ,@CntrCode = @x.query('//Cntr_Code').value('.', 'BIGINT')
            ,@StrtDate = @x.query('//Member_Ship').value('(Member_Ship/@strtdate)[1]', 'DATE')
            ,@EndDate = @x.query('//Member_Ship').value('(Member_Ship/@enddate)[1]', 'DATE')
            ,@NumbMontOfer = @x.query('//Member_Ship').value('(Member_Ship/@numbmontofer)[1]', 'INT')
            ,@NumbOfAttnMont = @x.query('//Member_Ship').value('(Member_Ship/@numbofattnmont)[1]', 'INT')
            ,@NumbOfAttnWeek = @x.query('//Member_Ship').value('(Member_Ship/@numbofattnweek)[1]', 'INT')
            ,@AttnDayType = @x.query('//Member_Ship').value('(Member_Ship/@attndaytype)[1]', 'VARCHAR(3)');
            
            --,@CochCrtfDate = @X.query('//Coch_Crtf_Date').value('.', 'DATE');
      SELECT @ActvTag = ISNULL(ACTV_TAG_DNRM, '101') FROM Fighter WHERE FILE_NO = @FileNo;
      -- Begin Check Validate
      IF LEN(@FrstName)        = 0 RAISERROR (N'برای فیلد "نام" درخواست اطلاعات وارد نشده' , 16, 1);
      IF LEN(@LastName)        = 0 RAISERROR (N'برای فیلد "نام خانوداگی" درخواست اطلاعات وارد نشده' , 16, 1);
      --IF LEN(@FathName)        = 0 RAISERROR (N'برای فیلد "نام پدر" درخواست اطلاعات وارد نشده' , 16, 1);
      IF LEN(@SexType)         = 0 RAISERROR (N'برای فیلد "جنسیت" درخواست اطلاعات وارد نشده' , 16, 1);
      IF @BrthDate             = '1900-01-01' SET @BrthDate = GETDATE()--RAISERROR (N'برای فیلد "تاریخ تولد" درخواست اطلاعات وارد نشده' , 16, 1);
      IF ISNULL(@DiseCode, 0)  = 0 SET @DiseCode = NULL;
      --IF ISNULL(@MtodCode, 0)  = 0 RAISERROR (N'برای فیلد "سبک" درخواست اطلاعات وارد نشده' , 16, 1);
      --IF ISNULL(@CtgyCode, 0) = 0 RAISERROR (N'برای فیلد "رده کمربندی" درخواست اطلاعات وارد نشده' , 16, 1);
      --IF ISNULL(@ClubCode, 0) = 0 RAISERROR (N'برای فیلد "باشگاه" درخواست اطلاعات وارد نشده' , 16, 1);
      IF LEN(@Type)            = 0 RAISERROR (N'برای فیلد "نوع هنرجو" درخواست اطلاعات وارد نشده' , 16, 1);
      IF ISNULL(@CbmtCode , 0) = 0 AND @Type IN ('001', '004') RAISERROR(N'ساعت کلاسی برای هنرجو وارد نشده', 16, 1);
      SET @SuntBuntDeptOrgnCode = CASE LEN(@SuntBuntDeptOrgnCode) WHEN 2 THEN @SuntBuntDeptOrgnCode ELSE '00'   END;
      SET @SuntBuntDeptCode     = CASE LEN(@SuntBuntDeptCode)     WHEN 2 THEN @SuntBuntDeptCode     ELSE '00'   END;
      SET @SuntBuntCode         = CASE LEN(@SuntBuntCode)         WHEN 2 THEN @SuntBuntCode         ELSE '00'   END;
      SET @SuntCode             = CASE LEN(@SuntCode)             WHEN 4 THEN @SuntCode             ELSE '0000' END;
      IF ISNULL(@NumbOfAttnMont, 0) > 0
      BEGIN
         IF ISNULL(@NumbOfAttnWeek, 0) = 0 SET @NumbOfAttnWeek = 3; --RAISERROR(N'برای ثبت نام جلسه ای باید تعداد روزهای حضور در هفته باید مشخص گردد', 16, 1);
         IF LEN(@AttnDayType) = 0 SET @AttnDayType = '003';--RAISERROR(N'برای ثبت نام جلسه ای باید روزهای حضور در هفته باید مشخص گردد.(زوج / فرد)', 16, 1);
      END
      
      -- هنرجو یا مهمان
      IF @Type IN ('001', '004', '005', '006')
         SELECT @MtodCode = MTOD_CODE
               ,@ClubCode = CLUB_CODE
               ,@CochFileNo = COCH_FILE_NO
               ,@DayType = DAY_TYPE
               ,@AttnTime = STRT_TIME
           FROM Club_Method
         WHERE CODE = @CbmtCode
      
      IF @Type IN ('006')
      BEGIN
         IF LEN(@InsrNumb) = 0 RAISERROR (N'برای فیلد "شماره بیمه" درخواست اطلاعات وارد نشده' , 16, 1);
         IF @InsrDate IN ('1900-01-01', '0001-01-01') RAISERROR (N'برای فیلد "تاریخ بیمه" درخواست اطلاعات وارد نشده' , 16, 1);
      END
      
      IF ISNULL(@ClubCode, 0) = 0 AND (SELECT COUNT(CODE) FROM Club) = 1
         SELECT TOP 1 @ClubCode = Code
           FROM Club;      
      
      IF ISNULL(@CtgyCode, 0) = 0
         SELECT @CtgyCode = Code
           FROM Category_Belt
          WHERE MTOD_CODE = @MtodCode
            AND ORDR = 0;      

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
           ,@Intr_File_No = @IntrFileNo
           ,@Cntr_Code = @CntrCode
           ,@Dpst_Acnt_Slry_Bank = NULL
           ,@Dpst_Acnt_Slry = NULL;
         
         EXEC dbo.INS_MBSP_P @Rqid = @Rqid, -- bigint
             @RqroRwno = @RqroRwno, -- smallint
             @FileNo = @FileNo, -- bigint
             @RectCode = '001', -- varchar(3)
             @Type = '001', -- varchar(3)
             @StrtDate = @StrtDate, -- date
             @EndDate = @EndDate, -- date
             @PrntCont = 0, -- smallint
             @NumbMontOfer = @NumbMontOfer,
             @NumbOfAttnMont = @NumbOfAttnMont,
             @NumbOfAttnWeek = @NumbOfAttnWeek,
             @AttnDayType = @AttnDayType;
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
           ,@Intr_File_No = @IntrFileNo
           ,@Cntr_Code = @CntrCode
           ,@Dpst_Acnt_Slry_Bank = NULL
           ,@Dpst_Acnt_Slry = NULL;
         
         EXEC dbo.UPD_MBSP_P @Rqid = @Rqid, -- bigint
             @RqroRwno = @RqroRwno, -- smallint
             @FileNo = @FileNo, -- bigint
             @RectCode = '001', -- varchar(3)
             @Type = '001', -- varchar(3)
             @StrtDate = @StrtDate, -- date
             @EndDate = @EndDate, -- date
             @PrntCont = 0, -- smallint
             @NumbMontOfer = @NumbMontOfer,
             @NumbOfAttnMont = @NumbOfAttnMont,
             @NumbOfAttnWeek = @NumbOfAttnWeek,
             @AttnDayType = @AttnDayType;
      END
      BEGIN                
         -- اگر در ثبت موقت باشیم و برای نوع درخواست و متقاضی آیین نامه هزینه داری داشته باشیم درخواست را به فرم اعلام هزینه ارسال میکنیم            
         IF EXISTS(
            SELECT *
              FROM Request_Row Rr, Fighter F, dbo.Fighter_Public P
             WHERE Rr.FIGH_FILE_NO = F.FILE_NO
               AND F.FILE_NO = P.FIGH_FILE_NO
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
                     --F.Mtod_Code_Dnrm , 
                     --F.Ctgy_Code_Dnrm)
                     P.MTOD_CODE,
                     P.CTGY_CODE)
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
            ELSE
            -- به درخواست آقای فهیم در تاریخ 1395/04/10 که مقرر گردید سیستم بتواند
            -- ثبت چند ماهی هم داشته باشد که بتوان هنرجویان را ترغیب به پرداخت هزینه
            -- شهریه باشگاه برای چندماه متوالی کرد
            BEGIN
                -- این شرط همیشه نادرست می باشد بخاطر اینکه در بالا اطلاعات سبک و رشته جدید بروز رسانی با مقدار جدید انجام میشود
                /*IF EXISTS (
                   SELECT *
                     FROM dbo.Fighter_Public Fp
                    WHERE Fp.RQRO_RQST_RQID = @Rqid
                      AND Fp.FIGH_FILE_NO = @FileNo
                      AND (
                          Fp.MTOD_CODE <> @MtodCode
                       OR Fp.CTGY_CODE <> @CtgyCode
                      )                     
                )*/
                BEGIN
                 UPDATE Request
                    SET SEND_EXPN = '001'
                       ,SSTT_MSTT_CODE = 1
                       ,SSTT_CODE = 1
                  WHERE RQID = @Rqid;                

                 --Raiserror('Raiseerror', 16, 1)
                 
                 /*DELETE Payment_Detail 
                  WHERE PYMT_RQST_RQID = @Rqid;          
                 DELETE Payment
                  WHERE RQST_RQID = @Rqid; */  
                 
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
                --ELSE
                BEGIN
                   DECLARE @Qnty SMALLINT;
                   
                   SELECT @Qnty = NUMB_OF_MONT_DNRM - ISNULL(NUMB_MONT_OFER, 0)
                     FROM dbo.Member_Ship
                    WHERE RQRO_RQST_RQID = @Rqid
                      AND RQRO_RWNO = @RqroRwno;
                   
                   --Raiserror(@Qnty, 16, 1)
                   PRINT @Qnty;
                   IF @Qnty <= 0
                   BEGIN
                      RAISERROR(N'تعداد ماه های تخفیف بیشتر از حد مجاز می باشد، لطفا اصلاح و دوباره امتحان کنید.', 16, 1);
                   END
                   
                   UPDATE dbo.Payment_Detail
                      SET QNTY = @Qnty
                    WHERE PYMT_RQST_RQID = @Rqid
                      AND RQRO_RWNO = @RqroRwno
                      AND ISNULL(ADD_QUTS, '001') = '001';                   
                END;
           END
         END
         ELSE
         BEGIN
            UPDATE Request
               SET SEND_EXPN = '001'
                  ,SSTT_MSTT_CODE = 1
                  ,SSTT_CODE = 1
             WHERE RQID = @Rqid;                
            
            --Raiserror('Raiseerror', 16, 1)
            
            DELETE Payment_Detail 
             WHERE PYMT_RQST_RQID = @Rqid;          
            DELETE Payment
             WHERE RQST_RQID = @Rqid;            
         END  
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
