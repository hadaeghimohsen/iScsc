SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[TST_SAVE_P]
	-- Add the parameters for the stored procedure here
	@X XML
	/* Sample Xml
   <Process>
      <Request rqid=""/>
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
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>77</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 77 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END

	DECLARE @ErrorMessage NVARCHAR(MAX);
	BEGIN TRAN T1;
	BEGIN TRY
	   DECLARE @Rqid     BIGINT
	          ,@PrvnCode VARCHAR(3)
	          ,@RegnCode VARCHAR(3);
   	
	   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]'        , 'BIGINT')
	         ,@PrvnCode = @X.query('//Request').value('(Request/@prvncode)[1]'    , 'VARCHAR(3)')
	         ,@RegnCode = @X.query('//Request').value('(Request/@regncode)[1]'    , 'VARCHAR(3)');
      
      DECLARE @FileNo   BIGINT
             ,@RqroRwno SMALLINT
             ,@Rslt     VARCHAR(3)
             ,@CrtfNumb VARCHAR(20)
             ,@CrtfDate DATE
             ,@GlobCode VARCHAR(20);
             
      DECLARE C$RQRV CURSOR FOR
         SELECT Rwno, Figh_File_No
           FROM Request_Row Rr, @X.nodes('//Request_Row')R(Rt)
          WHERE Rr.Rqst_Rqid = @Rqid            
            AND Rr.Recd_Stat = '002'
            /*AND Rr.Figh_File_No      = Rt.query('.').value('(Request_Row/@fileno)[1]', 'BIGINT')*/;
      
      OPEN C$RQRV;
      NextFromRqrv:
      FETCH NEXT FROM C$RQRV INTO @RqroRwno, @FileNo;
                     
      IF @@FETCH_STATUS <> 0   
         GOTO EndFetchRqrv;

      SELECT @Rslt = ISNULL(r.query('//Test').value('(Test/@rslt)[1]', 'VARCHAR(3)'), '004')
            ,@CrtfDate = r.query('//Test').value('(Test/@crtfdate)[1]', 'DATE')
            ,@CrtfNumb = r.query('//Test').value('(Test/@crtfnumb)[1]', 'VARCHAR(20)')
            ,@GlobCode = r.query('//Test').value('(Test/@globcode)[1]', 'VARCHAR(20)')
        FROM @X.nodes('//Request_Row') F(r)
       WHERE r.query('.').value('(Request_Row/@fileno)[1]', 'BIGINT') = @FileNo;
      
      IF @Rslt <> '001'
      BEGIN
         DELETE Fighter_Public WHERE RQRO_RQST_RQID = @Rqid AND RQRO_RWNO = @RqroRwno AND FIGH_FILE_NO = @FileNo;
         GOTO SaveResultTest;
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
             --,@GlobCode VARCHAR(20)
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
             ,@Password VARCHAR(250);
             
      SELECT @DiseCode = P.DISE_CODE
            ,@ClubCode = P.CLUB_CODE
            ,@FrstName = P.FRST_NAME
            ,@LastName = P.LAST_NAME
            ,@FathName = P.FATH_NAME
            ,@SexType  = P.SEX_TYPE
            ,@NatlCode = P.NATL_CODE
            ,@BrthDate = P.BRTH_DATE
            ,@CellPhon = P.CELL_PHON
            ,@TellPhon = P.TELL_PHON
            ,@CochDeg  = P.COCH_DEG
            ,@GudgDeg  = P.GUDG_DEG
            --,@GlobCode = P.GLOB_CODE
            ,@Type     = P.TYPE
            ,@PostAdrs = P.POST_ADRS
            ,@EmalAdrs = P.EMAL_ADRS
            ,@InsrNumb = P.INSR_NUMB
            ,@InsrDate = P.INSR_DATE
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
            ,@Password = P.PASS_WORD
        FROM Fighter_Public P, Fighter F
       WHERE P.FIGH_FILE_NO = @FileNo
         AND P.FIGH_FILE_NO = F.FILE_NO
         AND P.RWNO         = F.FGPB_RWNO_DNRM
         AND P.RECT_CODE    = '004';
      
      SELECT @MtodCode = CTGY_MTOD_CODE, @CtgyCode = CTGY_CODE
        FROM Test
       WHERE RQRO_RQST_RQID = @Rqid
         AND RQRO_RWNO      = @RqroRwno
         AND FIGH_FILE_NO   = @FileNo
         AND RECT_CODE      = '001';
                  
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
           ,@Pass_Word = @Password;
      END
      
      SaveResultTest:      
      SET @X = (
         SELECT 
            @Rqid AS '@rqid',
            @RqroRwno AS 'Request_Row/@rwno',
            @FileNo AS 'Request_Row/Fighter/@fileno',
            @Rslt   AS 'Request_Row/Fighter/Test/@rslt',
            @CrtfNumb AS 'Request_Row/Fighter/Test/@crtfnumb',
            @CrtfDate AS 'Request_Row/Fighter/Test/@crtfdate',
            @GlobCode AS 'Request_Row/Fighter/Test/@globcode'
         FOR XML PATH('Request'), ROOT('Process')
      );    
      EXEC TEST_SAVE_P @X;

      /*DECLARE @AttnDate DATE;
      SET @AttnDate = GETDATE();
      
      IF NOT EXISTS(
      SELECT * 
        FROM Attendance A
       WHERE A.FIGH_FILE_NO = @FileNo
         AND CAST(A.ATTN_DATE AS DATE) = CAST(@AttnDate AS DATE)
      )   
         EXEC INS_ATTN_P NULL, @FileNo, @AttnDate;
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
           FROM Test T
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

   /*
      SELECT
          ERROR_NUMBER() AS ErrorNumber
         ,ERROR_SEVERITY() AS ErrorSeverity
         ,ERROR_STATE() AS ErrorState
         ,ERROR_PROCEDURE() AS ErrorProcedure
         ,ERROR_LINE() AS ErrorLine
         ,ERROR_MESSAGE() AS ErrorMessage;
*/
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T1;
   END CATCH;   
END
GO
