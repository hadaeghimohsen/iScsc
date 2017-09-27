SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[OIC_CSAV_P]
   @X XML
AS 
BEGIN
      DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>189</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 189 سطوح امینتی', -- Message text.
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
	          ,@MtodCode BIGINT
	          ,@CtgyCode BIGINT
	          ,@StrtDate DATE
	          ,@EndDate DATE
	          ,@RqroRwno SMALLINT
	          ,@FileNo BIGINT;
   	
	   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT');
	   
	   SELECT @RqroRwno = RWNO
	         ,@FileNo = FIGH_FILE_NO
	     FROM Request_Row
	    WHERE RQST_RQID = @Rqid;
      
      SELECT @DiseCode = P.DISE_CODE
            ,@MtodCode = P.MTOD_CODE
            ,@CtgyCode = P.CTGY_CODE
            ,@ClubCode = P.CLUB_CODE
            ,@FrstName = P.FRST_NAME
            ,@LastName = P.LAST_NAME
            ,@FathName = P.FATH_NAME
            ,@SexType  = P.SEX_TYPE
            ,@NatlCode = P.NATL_CODE
            ,@BrthDate = P.BRTH_DATE
            ,@CellPhon = P.CELL_PHON
            ,@TellPhon = P.TELL_PHON
            ,@PostAdrs = P.POST_ADRS
            ,@EmalAdrs = P.EMAL_ADRS
            ,@InsrNumb = P.INSR_NUMB
            ,@InsrDate = P.INSR_DATE
            ,@EducDeg  = P.EDUC_DEG
            ,@CbmtCode = P.CBMT_CODE
            ,@BlodGrop = P.BLOD_GROP
            ,@RegnCode = P.REGN_CODE
            ,@PrvnCode = P.REGN_PRVN_CODE
            ,@CochFileNo = P.COCH_FILE_NO
            ,@DayType    = P.DAY_TYPE
            ,@AttnTime   = P.ATTN_TIME
            ,@FngrPrnt   = P.FNGR_PRNT
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
        FROM Fighter_Public P
       WHERE P.FIGH_FILE_NO = @FileNo
         AND P.RQRO_RQST_RQID = @Rqid
         AND P.RQRO_RWNO = @RqroRwno
         AND P.RECT_CODE = '001';
         
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
           ,@Sex_Type  = @SexType
           ,@Natl_Code = @NatlCode
           ,@Brth_Date = @BrthDate
           ,@Cell_Phon = @CellPhon
           ,@Tell_Phon = @TellPhon
           ,@Coch_Deg  = NULL
           ,@Gudg_Deg  = NULL
           ,@Glob_Code = NULL
           ,@Type      = '009'
           ,@Post_Adrs = @PostAdrs
           ,@Emal_Adrs = @EmalAdrs
           ,@Insr_Numb = @InsrNumb
           ,@Insr_Date = @InsrDate
           ,@Educ_Deg  = @EducDeg
           ,@Coch_File_No = @CochFileNo
           ,@Cbmt_Code = @CbmtCode
           ,@Day_Type  = @DayType
           ,@Attn_Time = @AttnTime
           ,@Coch_Crtf_Date = NULL
           ,@Calc_Expn_Type = NULL
           ,@Actv_Tag  = '101'
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
           ,@Dpst_Acnt_Slry = NULL;
      END
      ELSE
      BEGIN
         EXEC UPD_FGPB_P
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
           ,@Sex_Type  = @SexType
           ,@Natl_Code = @NatlCode
           ,@Brth_Date = @BrthDate
           ,@Cell_Phon = @CellPhon
           ,@Tell_Phon = @TellPhon
           ,@Coch_Deg  = NULL
           ,@Gudg_Deg  = NULL
           ,@Glob_Code = NULL
           ,@Type      = '009'
           ,@Post_Adrs = @PostAdrs
           ,@Emal_Adrs = @EmalAdrs
           ,@Insr_Numb = @InsrNumb
           ,@Insr_Date = @InsrDate
           ,@Educ_Deg  = @EducDeg
           ,@Coch_File_No = @CochFileNo
           ,@Cbmt_Code = @CbmtCode
           ,@Day_Type  = @DayType
           ,@Attn_Time = @AttnTime
           ,@Coch_Crtf_Date = NULL
           ,@Calc_Expn_Type = NULL
           ,@Actv_Tag  = '101'
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
           ,@Dpst_Acnt_Slry = NULL;
      END

      -- مرحله بعدی ثبت اطلاعات در جدول عضویت
      INSERT INTO Member_Ship (RQRO_RQST_RQID, RQRO_RWNO, FIGH_FILE_NO, RECT_CODE, [TYPE], STRT_DATE, END_DATE, NUMB_OF_ATTN_MONT)
      SELECT RQRO_RQST_RQID, RQRO_RWNO, FIGH_FILE_NO, '004', [TYPE], STRT_DATE, END_DATE, NUMB_OF_ATTN_MONT
        FROM Member_Ship
       WHERE RQRO_RQST_RQID = @Rqid
         AND RECT_CODE = '001';
      
      DECLARE @OldMbspRwno SMALLINT
             ,@NewMbspRwno SMALLINT
             ,@MbspFighFileNo BIGINT;
      
      SELECT @MbspFighFileNo = FIGH_FILE_NO
            ,@NewMbspRwno = RWNO
        FROM Member_Ship
       WHERE RQRO_RQST_RQID = @Rqid
         AND RECT_CODE = '004';         
     
      SELECT @OldMbspRwno = RWNO
        FROM Member_Ship
       WHERE RQRO_RQST_RQID = @Rqid
         AND RECT_CODE = '001';         
      
      INSERT INTO [Session] (MBSP_FIGH_FILE_NO, MBSP_RECT_CODE, MBSP_RWNO, SNID, SESN_TYPE, TOTL_SESN, CARD_NUMB, EXPN_CODE, CBMT_CODE)
      SELECT MBSP_FIGH_FILE_NO, '004', @NewMbspRwno, dbo.GNRT_NVID_U(), SESN_TYPE, TOTL_SESN, CARD_NUMB, EXPN_CODE, CBMT_CODE
        FROM [Session] 
       WHERE MBSP_FIGH_FILE_NO = @MbspFighFileNo
         AND MBSP_RECT_CODE = '001'
         AND MBSP_RWNO = @OldMbspRwno;
      
      DECLARE @Snid BIGINT;
      
      SELECT @Snid = SNID
        FROM [Session] 
       WHERE MBSP_FIGH_FILE_NO = @MbspFighFileNo
         AND MBSP_RECT_CODE = '004'
         AND MBSP_RWNO = @NewMbspRwno;
      
      UPDATE Payment_Detail
         SET PAY_STAT = '002'
            ,RCPT_MTOD = @x.query('//Payment_Detail[@code=sql:column("Code")]').value('(Payment_Detail/@rcptmtod)[1]', 'VARCHAR(3)')
       WHERE PYMT_RQST_RQID = @Rqid
         AND PAY_STAT = '001'
         AND @x.query('//Payment').value('(Payment/@setondebt)[1]', 'BIT') = 0;
      
      -- بروزرسانی اطلاعات مربی برای هزینه
      UPDATE pd
         SET FIGH_FILE_NO = s.COCH_FILE_NO_DNRM
            ,CBMT_CODE_DNRM = s.CBMT_CODE
        FROM Payment_Detail pd, dbo.Session s, dbo.Member_Ship m
       WHERE pd.PYMT_RQST_RQID = @Rqid
         AND pd.EXPN_CODE = s.EXPN_CODE
         AND s.MBSP_FIGH_FILE_NO = m.FIGH_FILE_NO
         AND s.MBSP_RECT_CODE = m.RECT_CODE
         AND s.MBSP_RWNO = m.RWNO
         AND m.RQRO_RQST_RQID = pd.PYMT_RQST_RQID;
       
      
      UPDATE Request
         SET RQST_STAT = '002'
       WHERE RQID = @Rqid;
      
      UPDATE Fighter
         SET CONF_STAT = '002'
       WHERE FILE_NO = @FileNo;
     
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
