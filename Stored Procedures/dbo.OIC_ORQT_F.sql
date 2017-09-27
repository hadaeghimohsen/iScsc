SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[OIC_ORQT_F] 
   @X XML
AS 
BEGIN
   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>162</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 162 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END

   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>163</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 163 سطوح امینتی', -- Message text.
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
	           @MdulName VARCHAR(11),
	           @SctnName VARCHAR(11),
	           
              @SuntBuntDeptOrgnCode VARCHAR(2),
              @SuntBuntDeptCode VARCHAR(2),
              @SuntBuntCode VARCHAR(2),
              @SuntCode VARCHAR(4),

	           @CardNumb VARCHAR(50),
	           @ExpnCode BIGINT,
	           @TotlSesn SMALLINT,
	           @FngrPrnt VARCHAR(20);
   	
   	DECLARE @FileNo BIGINT;
	   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT')
	         ,@RqtpCode = @X.query('//Request').value('(Request/@rqtpcode)[1]', 'VARCHAR(3)') -- 016
	         ,@RqttCode = @X.query('//Request').value('(Request/@rqttcode)[1]', 'VARCHAR(3)') -- 007
	         ,@RegnCode = @X.query('//Request').value('(Request/@regncode)[1]', 'VARCHAR(3)')
	         ,@PrvnCode = @X.query('//Request').value('(Request/@prvncode)[1]', 'VARCHAR(3)')
	         ,@ClubCode = @X.query('//Request').value('(Request/@clubcode)[1]', 'BIGINT')
	         ,@MdulName = @X.query('//Request').value('(Request/@mdulname)[1]', 'VARCHAR(11)')
	         ,@SctnName = @X.query('//Request').value('(Request/@sctnname)[1]', 'VARCHAR(11)')
	         
	         ,@SuntBuntDeptOrgnCode = @X.query('//Fighter_Public').value('(Fighter_Public/@suntbuntdeptorgncode)[1]', 'VARCHAR(2)')
	         ,@SuntBuntDeptCode = @X.query('//Fighter_Public').value('(Fighter_Public/@suntbuntdeptcode)[1]', 'VARCHAR(2)')
	         ,@SuntBuntCode = @X.query('//Fighter_Public').value('(Fighter_Public/@suntbuntcode)[1]', 'VARCHAR(2)')
	         ,@SuntCode = @X.query('//Fighter_Public').value('(Fighter_Public/@suntcode)[1]', 'VARCHAR(4)')
	         
	         ,@CardNumb = @X.query('//Session').value('(Session/@cardnumb)[1]', 'VARCHAR(50)')
	         ,@ExpnCode = @X.query('//Session').value('(Session/@expncode)[1]', 'BIGINT')
	         ,@TotlSesn = @X.query('//Session').value('(Session/@totlsesn)[1]', 'SMALLINT')
	         ,@FngrPrnt = @X.query('//Session').value('(Session/@fngrprnt)[1]', 'VARCHAR(20)');
      
/*      IF @CardNumb IS NULL
         SET @CardNumb = @FngrPrnt; */
      
      SET @SuntBuntDeptOrgnCode = CASE LEN(@SuntBuntDeptOrgnCode) WHEN 2 THEN @SuntBuntDeptOrgnCode ELSE '00'   END;
      SET @SuntBuntDeptCode     = CASE LEN(@SuntBuntDeptCode)     WHEN 2 THEN @SuntBuntDeptCode     ELSE '00'   END;
      SET @SuntBuntCode         = CASE LEN(@SuntBuntCode)         WHEN 2 THEN @SuntBuntCode         ELSE '00'   END;
      SET @SuntCode             = CASE LEN(@SuntCode)             WHEN 4 THEN @SuntCode             ELSE '0000' END;

      IF LEN(@CardNumb) = 0 BEGIN RAISERROR(N'ورود شماره کارت الزامی می باشد', 16, 1); RETURN; END
      IF @ExpnCode = 0 BEGIN RAISERROR(N'ورود شرکت در جلسه الزامی می باشد', 16, 1); RETURN; END
      IF @TotlSesn = 0 BEGIN RAISERROR(N'ورود تعداد اعضا الزامی می باشد', 16, 1); RETURN; END
      IF EXISTS(
         SELECT * 
           FROM Fighter
          WHERE CARD_NUMB_DNRM = @CardNumb
            --AND FNGR_PRNT_DNRM = @FngrPrnt
      )
      BEGIN
         RAISERROR(N'این شماره کارت توسط فرد دیگری رزرو شده، لطفا شماره کارت دیگری را انتخاب کنید', 16, 1); 
         RETURN;
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

         UPDATE Request
            SET MDUL_NAME = @MdulName
              ,SECT_NAME = @SctnName
          WHERE RQID = @Rqid;    
      END

      -- ثبت یا به کارگیری مشترک رزرو ساعتی در جدول های مربوطه
      SELECT TOP 1 
             @FileNo = FILE_NO
        FROM Fighter
       WHERE (RQST_RQID = @Rqid
         AND  FGPB_TYPE_DNRM = '008' 
         AND  FIGH_STAT = '001'
         AND  CONF_STAT = '002'
         AND  REGN_PRVN_CODE = @PrvnCode
         AND  REGN_CODE = @RegnCode
         AND  CLUB_CODE_DNRM = @ClubCode) 
          OR
             (FGPB_TYPE_DNRM = '008'
         AND  FIGH_STAT = '002'
         AND  CONF_STAT = '002'
         AND  REGN_PRVN_CODE = @PrvnCode
         AND  REGN_CODE = @RegnCode
         AND  CLUB_CODE_DNRM = @ClubCode);
      
      IF @FileNo IS NULL OR @FileNo = 0
      BEGIN
         -- ثبت شماره پرونده 
         EXEC dbo.INS_FIGH_P @Rqid, @PrvnCode, @RegnCode, @FileNo OUT;
         
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
              ,@Dise_Code = NULL
              ,@Mtod_Code = NULL
              ,@Ctgy_Code = NULL
              ,@Club_Code = @ClubCode
              ,@Rqro_Rqst_Rqid = @Rqid
              ,@Rqro_Rwno = @RqroRwno
              ,@Rect_Code = '004'
              ,@Frst_Name = N'مشتری'
              ,@Last_Name = N'جلسه ای'
              ,@Fath_Name = NULL
              ,@Sex_Type = NULL
              ,@Natl_Code = NULL
              ,@Brth_Date = NULL
              ,@Cell_Phon = NULL
              ,@Tell_Phon = NULL
              ,@Coch_Deg  = NULL
              ,@Gudg_Deg = NULL
              ,@Glob_Code = NULL
              ,@Type      = '008'
              ,@Post_Adrs = NULL
              ,@Emal_Adrs = NULL
              ,@Insr_Numb = NULL
              ,@Insr_Date = NULL
              ,@Educ_Deg   = NULL
              ,@Coch_File_No = NULL
              ,@Cbmt_Code = NULL
              ,@Day_Type = NULL
              ,@Attn_Time = NULL
              ,@Coch_Crtf_Date = NULL
              ,@Calc_Expn_Type = NULL
              ,@Actv_Tag = '101'
              ,@Blod_Grop = NULL
              ,@Fngr_Prnt = @FngrPrnt
              ,@Sunt_Bunt_Dept_Orgn_Code = @SuntBuntDeptOrgnCode
              ,@Sunt_Bunt_Dept_Code = @SuntBuntDeptCode
              ,@Sunt_Bunt_Code = @SuntBuntCode
              ,@Sunt_Code = @SuntCode
              ,@Cord_X = NULL
              ,@Cord_Y = NULL
              ,@Most_Debt_Clng = NULL
              ,@Serv_No = NULL
              ,@Brth_Plac = NULL
              ,@Issu_Plac = NULL
              ,@Hist_Desc = NULL
              ,@Fath_Work = NULL
              ,@Intr_File_No = NULL
              ,@Cntr_Code = NULL
              ,@Dpst_Acnt_Slry_Bank = NULL
              ,@Dpst_Acnt_Slry = NULL;
         END
         UPDATE Fighter
            SET CONF_STAT = '002'
          WHERE FILE_NO = @FileNo;
      END
      ELSE
      BEGIN
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

         IF NOT EXISTS(
            SELECT *
              FROM dbo.Fighter_Public
             WHERE RQRO_RQST_RQID = @Rqid
               AND RQRO_RWNO = @RqroRwno
               AND RECT_CODE = '004'
               AND FIGH_FILE_NO = @FileNo
         )
         BEGIN
            EXEC INS_FGPB_P
               @Prvn_Code = @PrvnCode
              ,@Regn_Code = @RegnCode
              ,@File_No   = @FileNo
              ,@Dise_Code = NULL
              ,@Mtod_Code = NULL
              ,@Ctgy_Code = NULL
              ,@Club_Code = @ClubCode
              ,@Rqro_Rqst_Rqid = @Rqid
              ,@Rqro_Rwno = @RqroRwno
              ,@Rect_Code = '004'
              ,@Frst_Name = N'مشتری'
              ,@Last_Name = N'جلسه ای'
              ,@Fath_Name = NULL
              ,@Sex_Type = NULL
              ,@Natl_Code = NULL
              ,@Brth_Date = NULL
              ,@Cell_Phon = NULL
              ,@Tell_Phon = NULL
              ,@Coch_Deg  = NULL
              ,@Gudg_Deg = NULL
              ,@Glob_Code = NULL
              ,@Type      = '008'
              ,@Post_Adrs = NULL
              ,@Emal_Adrs = NULL
              ,@Insr_Numb = NULL
              ,@Insr_Date = NULL
              ,@Educ_Deg   = NULL
              ,@Coch_File_No = NULL
              ,@Cbmt_Code = NULL
              ,@Day_Type = NULL
              ,@Attn_Time = NULL
              ,@Coch_Crtf_Date = NULL
              ,@Calc_Expn_Type = NULL
              ,@Actv_Tag = '101'
              ,@Blod_Grop = NULL
              ,@Fngr_Prnt = @FngrPrnt
              ,@Sunt_Bunt_Dept_Orgn_Code = @SuntBuntDeptOrgnCode
              ,@Sunt_Bunt_Dept_Code = @SuntBuntDeptCode
              ,@Sunt_Bunt_Code = @SuntBuntCode
              ,@Sunt_Code = @SuntCode
              ,@Cord_X = NULL
              ,@Cord_Y = NULL
              ,@Most_Debt_Clng = NULL
              ,@Serv_No = NULL
              ,@Brth_Plac = NULL
              ,@Issu_Plac = NULL
              ,@Hist_Desc = NULL
              ,@Fath_Work = NULL
              ,@Intr_File_No = NULL
              ,@Cntr_Code = NULL
              ,@Dpst_Acnt_Slry_Bank = NULL
              ,@Dpst_Acnt_Slry = NULL;
         END
         ELSE
         BEGIN
            EXEC UPD_FGPB_P
               @Prvn_Code = @PrvnCode
              ,@Regn_Code = @RegnCode
              ,@File_No   = @FileNo
              ,@Dise_Code = NULL
              ,@Mtod_Code = NULL
              ,@Ctgy_Code = NULL
              ,@Club_Code = @ClubCode
              ,@Rqro_Rqst_Rqid = @Rqid
              ,@Rqro_Rwno = @RqroRwno
              ,@Rect_Code = '004'
              ,@Frst_Name = N'مشتری'
              ,@Last_Name = N'جلسه ای'
              ,@Fath_Name = NULL
              ,@Sex_Type = NULL
              ,@Natl_Code = NULL
              ,@Brth_Date = NULL
              ,@Cell_Phon = NULL
              ,@Tell_Phon = NULL
              ,@Coch_Deg  = NULL
              ,@Gudg_Deg = NULL
              ,@Glob_Code = NULL
              ,@Type      = '008'
              ,@Post_Adrs = NULL
              ,@Emal_Adrs = NULL
              ,@Insr_Numb = NULL
              ,@Insr_Date = NULL
              ,@Educ_Deg   = NULL
              ,@Coch_File_No = NULL
              ,@Cbmt_Code = NULL
              ,@Day_Type = NULL
              ,@Attn_Time = NULL
              ,@Coch_Crtf_Date = NULL
              ,@Calc_Expn_Type = NULL
              ,@Actv_Tag = '101'
              ,@Blod_Grop = NULL
              ,@Fngr_Prnt = @FngrPrnt
              ,@Sunt_Bunt_Dept_Orgn_Code = @SuntBuntDeptOrgnCode
              ,@Sunt_Bunt_Dept_Code = @SuntBuntDeptCode
              ,@Sunt_Bunt_Code = @SuntBuntCode
              ,@Sunt_Code = @SuntCode
              ,@Cord_X = NULL
              ,@Cord_Y = NULL
              ,@Most_Debt_Clng = NULL
              ,@Serv_No = NULL
              ,@Brth_Plac = NULL
              ,@Issu_Plac = NULL
              ,@Hist_Desc = NULL
              ,@Fath_Work = NULL
              ,@Intr_File_No = NULL
              ,@Cntr_Code = NULL
              ,@Dpst_Acnt_Slry_Bank = NULL
              ,@Dpst_Acnt_Slry = NULL;
         END
      END

      -- ثبت ردیف درخواست 
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
      
      -- مرحله بعدی ثبت اطلاعات در جدول عضویت
      IF NOT EXISTS(
         SELECT *
           FROM Member_Ship
          WHERE RQRO_RQST_RQID = @Rqid
            AND RQRO_RWNO = @RqroRwno
            AND FIGH_FILE_NO = @FileNo
            AND RECT_CODE = '001'
            AND [TYPE] = '001'
      )
      BEGIN
         INSERT INTO Member_Ship (RQRO_RQST_RQID,RQRO_RWNO, FIGH_FILE_NO, RECT_CODE, [TYPE], STRT_DATE, END_DATE)
         VALUES                  (@Rqid,         @RqroRwno, @FileNo,      '001',     '001', GETDATE(), DATEADD(MINUTE ,90 , GETDATE()));
      END
      
      DECLARE @MbspRwno SMALLINT;
      SELECT @MbspRwno = RWNO
        FROM Member_Ship
       WHERE RQRO_RQST_RQID = @Rqid
         AND RQRO_RWNO = @RqroRwno
         AND FIGH_FILE_NO = @FileNo
         AND [TYPE] = '001'
         AND RECT_CODE = '001';
      
      DECLARE @Snid BIGINT;
      SELECT TOP 1
             @Snid = SNID
        FROM [Session]
       WHERE MBSP_FIGH_FILE_NO = @FileNo
         AND MBSP_RECT_CODE = '001'
         AND MBSP_RWNO = @MbspRwno
         AND SESN_TYPE = '002'
         AND SNID = (SELECT MAX(SNID)
                          FROM [Session]
                         WHERE MBSP_FIGH_FILE_NO = @FileNo
                           AND MBSP_RECT_CODE = '001'
                           AND MBSP_RWNO = @MbspRwno
                       );
      IF @Snid IS NULL OR @Snid = 0
      BEGIN
         SET @Snid = dbo.GNRT_NVID_U();
         INSERT INTO [Session] (MBSP_FIGH_FILE_NO, MBSP_RECT_CODE, MBSP_RWNO, SNID, SESN_TYPE, EXPN_CODE, CARD_NUMB, TOTL_SESN)
         VALUES(@FileNo, '001', @MbspRwno, @Snid, '002', @ExpnCode, @CardNumb, @TotlSesn);
      END
      ELSE
         UPDATE [Session]
            SET EXPN_CODE = @ExpnCode
               ,CARD_NUMB = @CardNumb
               ,TOTL_SESN = @TotlSesn
          WHERE MBSP_FIGH_FILE_NO = @FileNo
            AND MBSP_RECT_CODE = '001'
            AND MBSP_RWNO = @MbspRwno
            AND SNID = @Snid;

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
