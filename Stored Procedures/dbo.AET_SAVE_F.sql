SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- ============================================
CREATE PROCEDURE [dbo].[AET_SAVE_F]
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
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>140</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 140 سطوح امینتی', -- Message text.
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
       WHERE PYMT_RQST_RQID = @Rqid
         AND @x.query('//Payment').value('(Payment/@setondebt)[1]', 'BIT') = 0;
      
      /* ثبت شماره درخواست */
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
      /*BEGIN
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
      
      DECLARE @FileNo BIGINT;      

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
           
      /*IF @RqroRwno IS NULL
      BEGIN
         EXEC INS_RQRO_P
            @Rqid
           ,@FileNo
           ,@RqroRwno OUT;
      END*/
      
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
             ,@ChatId BIGINT;
             
      
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
             ,@MtodCode = p.MTOD_CODE
             ,@CtgyCode = p.CTGY_CODE
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
         FROM Fighter_Public P
        WHERE P.FIGH_FILE_NO = @FileNo
          AND P.RQRO_RQST_RQID = @Rqid
          AND P.RQRO_RWNO = @RqroRwno
          AND P.RECT_CODE = '001';
      
      IF LEN(@ActvTag) <> 3 BEGIN RAISERROR(N'شاخص فعالیت وارد نشده', 16, 1); END  
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
           ,@Chat_Id = @ChatId;
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
           ,@Intr_File_No = @IntrFileNo
           ,@Cntr_Code = @CntrCode
           ,@Dpst_Acnt_Slry_Bank = @DpstAcntSlryBank
           ,@Dpst_Acnt_Slry = @DpstAcntSlry
           ,@Chat_Id = @ChatId;
      END
      
      /*DECLARE @AttnDate DATE;
      SET @AttnDate = GETDATE();
      
      IF NOT EXISTS(
      SELECT * 
        FROM Attendance A
       WHERE A.FIGH_FILE_NO = @FileNo
         AND CAST(A.ATTN_DATE AS DATE) = CAST(@AttnDate AS DATE)
      )   
         EXEC INS_ATTN_P @ClubCode, @FileNo, @AttnDate;
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
