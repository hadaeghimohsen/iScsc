SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CMC_RQST_F]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	/*
	   شرایط ارسال داده ها مربوط به جدول درخواست
	   1 - درخواست جدید می باشد و ستون شماره درخواست خالی می باشد
	   2 - درخواست قبلا ثبت شده و ستون شماره درخواست خالی نمی باشد
	*/
   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>110</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 110 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END

   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>111</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 111 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>112</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 112 سطوح امینتی', -- Message text.
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
      /*ELSE
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
             ,@IntrFileNo BIGINT
             ,@CntrCode BIGINT;
      
      DECLARE @CrtfDate DATE
             ,@CrtfNumb VARCHAR(20)
             ,@TestDate DATE;
      
      DECLARE @OldMtodCode BIGINT
             ,@OldCtgyCode BIGINT;

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
             ,@OldMtodCode  = F.MTOD_CODE_DNRM
             ,@OldCtgyCode  = F.CTGY_CODE_DNRM
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
         FROM Fighter F, Fighter_Public P
        WHERE F.FILE_NO = @FileNo
          AND F.FILE_NO = P.FIGH_FILE_NO
          AND F.FGPB_RWNO_DNRM = P.RWNO
          AND P.RECT_CODE = '004';
             
      /*IF EXISTS(
         SELECT *
           FROM Fighter_Public
          WHERE RQRO_RQST_RQID = @Rqid
            AND FIGH_FILE_NO   = @FileNo
            AND RECT_CODE      = '001'
      )*/
      BEGIN
       SELECT @CrtfDate = r.query('ChngMtodCtgy/Crtf_Date').value('.', 'DATE')
             ,@CrtfNumb = r.query('ChngMtodCtgy/Crtf_Numb').value('.', 'VARCHAR(20)')
             ,@TestDate = r.query('ChngMtodCtgy/Test_Date').value('.', 'DATE')
             ,@GlobCode = CASE WHEN LEN(r.query('ChngMtodCtgy/Glob_Code').value('.', 'VARCHAR(20)')) = 0 THEN @GlobCode ELSE r.query('ChngMtodCtgy/Glob_Code').value('.', 'VARCHAR(20)')END
             ,@MtodCode = r.query('ChngMtodCtgy/Mtod_Code').value('.', 'BIGINT')
             ,@CtgyCode = r.query('ChngMtodCtgy/Ctgy_Code').value('.', 'BIGINT')
         FROM @X.nodes('//Request_Row')Rr(r)
        WHERE r.query('.').value('(Request_Row/@fileno)[1]', 'BIGINT') = @FileNo;
       
         -- Begin Check Validate
         --IF ISNULL(@MtodCode, 0) = 0 RAISERROR (N'برای فیلد "سبک" درخواست اطلاعات وارد نشده' , 16, 1);
         --IF ISNULL(@CtgyCode, 0) = 0 RAISERROR (N'برای فیلد "رده کمربند" درخواست اطلاعات وارد نشده' , 16, 1);
         IF @MtodCode = 0 OR @CtgyCode  = 0 OR @MtodCode IS NULL OR @CtgyCode IS NULL
         BEGIN
            SET @MtodCode = @OldMtodCode;         
            SET @CtgyCode = @OldCtgyCode;
         END
         
         IF @CtgyCode <> @OldCtgyCode
         BEGIN
            --IF @MtodCode <> @OldMtodCode 
            BEGIN
               IF EXISTS(SELECT * FROM Category_Belt WHERE MTOD_CODE = @MtodCode AND CODE = @CtgyCode AND ORDR > 0)
               BEGIN
                  IF LEN(@CrtfNumb) = 0
                  BEGIN
                     SELECT TOP 1 
                            @CrtfNumb = T.CRTF_NUMB
                           ,@CrtfDate = T.CRTF_DATE
                           ,@TestDate = T.TEST_DATE                           
                       FROM Test T
                      WHERE T.FIGH_FILE_NO = @FileNo
                        AND RECT_CODE = '004'
                   ORDER BY T.RWNO DESC;
                     IF LEN(@CrtfNumb) = 0 AND 
                     NOT EXISTS(
                        SELECT *
                          FROM Test
                         WHERE RQRO_RQST_RQID = @Rqid
                           AND RQRO_RWNO      = @RqroRwno
                           AND FIGH_FILE_NO   = @FileNo
                           AND RECT_CODE      = '001'
                     )
                     BEGIN
                        SET @CrtfDate = GETDATE();
                        SET @TestDate = GETDATE();                        
                        EXEC INS_TEST_P
                           @Rqid
                          ,@RqroRwno
                          ,@FileNo
                          ,'001'
                          ,@CrtfDate
                          ,'0'
                          ,@TestDate
                          ,'001'
                          ,@MtodCode
                          ,@CtgyCode
                          ,@GlobCode;                        
                        GOTO INS_PBLC_L;
                     END
                  END
                  ELSE
                  BEGIN
                     IF LEN(@CrtfNumb)       = 0 RAISERROR (N'برای فیلد "شماره حکم" درخواست اطلاعات وارد نشده' , 16, 1);
                     IF @CrtfDate = '1900-01-01' RAISERROR (N'برای فیلد "تاریخ صدور حکم" درخواست اطلاعات وارد نشده' , 16, 1);
                     IF @TestDate = '1900-01-01' RAISERROR (N'برای فیلد "تاریخ آزمون" درخواست اطلاعات وارد نشده' , 16, 1);               
                  END
                  IF NOT EXISTS(
                     SELECT *
                       FROM Test
                      WHERE RQRO_RQST_RQID = @Rqid
                        AND RQRO_RWNO      = @RqroRwno
                        AND FIGH_FILE_NO   = @FileNo
                        AND RECT_CODE      = '001'
                  )
                  BEGIN
                     EXEC INS_TEST_P
                        @Rqid
                       ,@RqroRwno
                       ,@FileNo
                       ,'001'
                       ,@CrtfDate
                       ,@CrtfNumb
                       ,@TestDate
                       ,'001'
                       ,@MtodCode
                       ,@CtgyCode
                       ,@GlobCode;                        
                  END
                  ELSE
                  BEGIN
                     EXEC UPD_TEST_P
                        @Rqid
                       ,@RqroRwno
                       ,@FileNo
                       ,'001'
                       ,@CrtfDate
                       ,@CrtfNumb
                       ,@TestDate
                       ,'001'
                       ,@MtodCode
                       ,@CtgyCode
                       ,@GlobCode;                        
                  END
               END -- EXISTS
               ELSE
                  DELETE Test 
                   WHERE RQRO_RQST_RQID = @Rqid
                     AND RQRO_RWNO      = @RqroRwno
                     AND RECT_CODE      = '001';
            END -- @MtodCode <> @OldMtodCode 
         END -- @CtgyCode <> @OldCtgyCode       
         ELSE IF EXISTS(SELECT * FROM Fighter_Public WHERE RQRO_RQST_RQID = @Rqid AND RQRO_RWNO = @RqroRwno AND RECT_CODE = '001')
         BEGIN
            SET @ErrorMessage = N'رده کمربند برای ردیف ' + CAST(@RqroRwno AS VARCHAR(5)) + N' تغيير نكرده است ';
            RAISERROR(@ErrorMessage, 16, 1);
            /* DELETE Test 
             WHERE RQRO_RQST_RQID = @Rqid
               AND RQRO_RWNO      = @RqroRwno
               AND RECT_CODE      = '001';  */
         -- End   Check Validate
         END
      END
      
      INS_PBLC_L:
      /* ثبت اطلاعات عمومی پرونده */
      IF NOT EXISTS(
         SELECT * 
         FROM Fighter_Public
         WHERE FIGH_FILE_NO = @FileNo
           AND RQRO_RQST_RQID = @Rqid
           AND RQRO_RWNO = @RqroRwno
           AND RECT_CODE = '001'
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
           ,@Dpst_Acnt_Slry_Bank = NULL
           ,@Dpst_Acnt_Slry = NULL;
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
           ,@Dpst_Acnt_Slry_Bank = NULL
           ,@Dpst_Acnt_Slry = NULL;
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
         DELETE Payment
          WHERE RQST_RQID = @Rqid;            
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
