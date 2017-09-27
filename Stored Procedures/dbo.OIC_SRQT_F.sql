SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[OIC_SRQT_F]
   @X XML
AS
   /*
      <Process>
         <Request rqid="" regncode="" prvncode="" rqtpcode="" rqttcode="" clubcode="">
            <Session timewate="">
               <Session_Meeting rwno="" valdtype="" strttime="" endtime="" tempendtime="" expncode=""/>
            </Session>
         </Request>
      </Process>
   */
BEGIN

   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>158</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 158 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END

   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>159</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 159 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
	DECLARE @ErrorMessage NVARCHAR(MAX);
	BEGIN TRAN OIC_SRQT_F_T1;
	BEGIN TRY
	   DECLARE @Rqid     BIGINT,
	           @RqtpCode VARCHAR(3),
	           @RqttCode VARCHAR(3),
	           @RegnCode VARCHAR(3),
	           @PrvnCode VARCHAR(3),
	           @ClubCode BIGINT,
	           @MdulName VARCHAR(11),
	           @SctnName VARCHAR(11),
	           
	           @TimeWate TIME(0);
   	
   	DECLARE @FileNo BIGINT;
	   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT')
	         ,@RqtpCode = @X.query('//Request').value('(Request/@rqtpcode)[1]', 'VARCHAR(3)') -- 016
	         ,@RqttCode = @X.query('//Request').value('(Request/@rqttcode)[1]', 'VARCHAR(3)') -- 007
	         --,@RegnCode = @X.query('//Request').value('(Request/@regncode)[1]', 'VARCHAR(3)')
	         --,@PrvnCode = @X.query('//Request').value('(Request/@prvncode)[1]', 'VARCHAR(3)')
	         ,@ClubCode = @X.query('//Request').value('(Request/@clubcode)[1]', 'BIGINT')
	         ,@MdulName = @X.query('//Request').value('(Request/@mdulname)[1]', 'VARCHAR(11)')
	         ,@SctnName = @X.query('//Request').value('(Request/@sctnname)[1]', 'VARCHAR(11)')
	         ,@TimeWate = @X.query('//Session').value('(Session/@timewate)[1]', 'TIME(0)');
      
      IF (@Rqid IS NULL OR @Rqid = 0) AND (@ClubCode IS NULL OR @ClubCode = 0) RAISERROR (N'باشگاه مشخص نیست', 16, 1);
      IF (@Rqid IS NULL OR @Rqid = 0)
         SELECT @RegnCode = REGN_CODE
               ,@PrvnCode = REGN_PRVN_CODE
           FROM dbo.Club
          WHERE Code = @ClubCode;
      ELSE
       SELECT @RegnCode = REGN_CODE
             ,@PrvnCode = REGN_PRVN_CODE
           FROM dbo.Request
          WHERE Rqid = @Rqid;
          
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
         
         --SELECT * FROM Request WHERE RQID = @Rqid;
      END
      ELSE 
      BEGIN
         SELECT @PrvnCode = REGN_PRVN_CODE
               ,@RegnCode = REGN_CODE
               ,@ClubCode = CLUB_CODE_DNRM
           FROM Fighter
          WHERE RQST_RQID = @Rqid;
      END

      -- ثبت یا به کارگیری مشترک رزرو ساعتی در جدول های مربوطه
      SELECT TOP 1 
             @FileNo = FILE_NO
        FROM Fighter
       WHERE (RQST_RQID = @Rqid
         AND  FGPB_TYPE_DNRM = '007' 
         AND  FIGH_STAT = '001'
         AND  CONF_STAT = '002'
         AND  REGN_PRVN_CODE = @PrvnCode
         AND  REGN_CODE = @RegnCode
         AND  CLUB_CODE_DNRM = @ClubCode) 
          OR
             (FGPB_TYPE_DNRM = '007'
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
              ,@Last_Name = N'رزرو ساعتی'
              ,@Fath_Name = NULL
              ,@Sex_Type = NULL
              ,@Natl_Code = NULL
              ,@Brth_Date = NULL
              ,@Cell_Phon = NULL
              ,@Tell_Phon = NULL
              ,@Coch_Deg  = NULL
              ,@Gudg_Deg = NULL
              ,@Glob_Code = NULL
              ,@Type      = '007'
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
              ,@Fngr_Prnt = NULL
              ,@Sunt_Bunt_Dept_Orgn_Code = NULL
              ,@Sunt_Bunt_Dept_Code = NULL
              ,@Sunt_Bunt_Code = NULL
              ,@Sunt_Code = NULL
              ,@Cord_X = NULL
              ,@Cord_Y = NULL
              ,@Most_Debt_Clng = NULL
              ,@Serv_No = NULL              
              ,@Brth_Plac = NULL
              ,@Issu_Plac = NULL
              ,@Fath_Work = NULL
              ,@Hist_Desc = NULL
              ,@Intr_File_No = NULL
              ,@Cntr_Code = NULL
              ,@Dpst_Acnt_Slry_Bank = NULL
              ,@Dpst_Acnt_Slry = NULL
              ;
              
         END
         UPDATE Fighter
            SET CONF_STAT = '002'
          WHERE FILE_NO = @FileNo;
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
         VALUES                  (@Rqid,         @RqroRwno, @FileNo,      '001',     '001', GETDATE(), DATEADD(HOUR ,1 , GETDATE()));
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
         AND SESN_TYPE = '001'
         AND SNID = (SELECT MAX(SNID)
                          FROM [Session]
                         WHERE MBSP_FIGH_FILE_NO = @FileNo
                           AND MBSP_RECT_CODE = '001'
                           AND MBSP_RWNO = @MbspRwno
                       );
      IF @Snid IS NULL OR @Snid = 0
      BEGIN
         SET @Snid = dbo.GNRT_NVID_U();
         INSERT INTO [Session] (MBSP_FIGH_FILE_NO, MBSP_RECT_CODE, MBSP_RWNO, SNID, SESN_TYPE, TIME_WATE)
         VALUES(@FileNo, '001', @MbspRwno, @Snid, '001', @TimeWate);
      END
      ELSE
         UPDATE [Session]
            SET TIME_WATE = @TimeWate
          WHERE MBSP_FIGH_FILE_NO = @FileNo
            AND MBSP_RECT_CODE = '001'
            AND MBSP_RWNO = @MbspRwno
            AND SNID = @Snid
      
      -- در این قسمت شروع به اضافه کردن آیتم های درآمدی که به صورت ساعتی اجاره داده می شوند نمایش داده می شود.
      DECLARE @SnmtRwno SMALLINT,
              @ValdType VARCHAR(3),
              @StrtTime TIME(0),
              @EndTime  TIME(0),
              @TempEndTime TIME(0),
              @ExpnCode BIGINT,
              @DateDiff INT,
              @ExpnPric INT,
              @ExpnExtrPrct INT;
      
      DECLARE C$Snmt CURSOR FOR
         SELECT r.query('.').value('(Session_Meeting/@rwno)[1]', 'SMALLINT') AS Rwno
               ,r.query('.').value('(Session_Meeting/@valdtype)[1]', 'VARCHAR(3)') AS Vald_Type
               ,r.query('.').value('(Session_Meeting/@strttime)[1]', 'TIME(0)') AS Strt_Time
               ,r.query('.').value('(Session_Meeting/@endtime)[1]', 'TIME(0)') AS End_Time
               ,r.query('.').value('(Session_Meeting/@tempendtime)[1]', 'TIME(0)') AS Temp_End_Time
               ,r.query('.').value('(Session_Meeting/@expncode)[1]', 'BIGINT') AS Expn_Code
           FROM @X.nodes('//Session_Meeting') Snmt(r);
      
      OPEN C$Snmt;
      L$FetchNextC$Snmt:
      FETCH NEXT FROM C$Snmt INTO @SnmtRwno, @ValdType, @StrtTime, @EndTime, @TempEndTime, @ExpnCode;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndFetchC$Snmt;
      
      SELECT @ExpnPric = PRIC
            ,@ExpnExtrPrct = EXTR_PRCT
        FROM Expense
       WHERE CODE = @ExpnCode;
      
      IF @SnmtRwno = 0 AND 
         NOT EXISTS(
         SELECT *
           FROM Session_Meeting
          WHERE MBSP_FIGH_FILE_NO = @FileNo
            AND MBSP_RECT_CODE = '001'
            AND MBSP_RWNO = @MbspRwno
            AND SESN_SNID = @Snid
            AND EXPN_CODE = @ExpnCode
            AND STRT_TIME IS NOT NULL
            AND END_TIME IS NULL
      )
      BEGIN         
         INSERT INTO Session_Meeting (MBSP_FIGH_FILE_NO, MBSP_RECT_CODE, MBSP_RWNO, EXPN_CODE, SESN_SNID, RWNO, VALD_TYPE)
         VALUES (@FileNo, '001', @MbspRwno, @ExpnCode, @Snid, 0, '002');
      END
      ELSE IF @EndTime = '00:00:00' AND @TempEndTime != '00:00:00'
      BEGIN 
         SET @DateDiff = DATEDIFF(MINUTE, @StrtTime, @TempEndTime);
         UPDATE Session_Meeting
            SET EXPN_PRIC = ROUND(@ExpnPric * @DateDiff / 60, -3)
               ,EXPN_EXTR_PRCT = ROUND(@ExpnExtrPrct * @DateDiff / 60, -3)
          WHERE MBSP_FIGH_FILE_NO = @FileNo
            AND MBSP_RECT_CODE = '001'
            AND MBSP_RWNO = @MbspRwno
            AND SESN_SNID = @Snid
            AND RWNO = @SnmtRwno
            AND END_TIME IS NULL;
      END
      ELSE IF @EndTime != '00:00:00' 
      BEGIN 
         SET @DateDiff = DATEDIFF(MINUTE, @StrtTime, @EndTime);
         UPDATE Session_Meeting
            SET EXPN_PRIC = ROUND(@ExpnPric * @DateDiff / 60, -3)
               ,EXPN_EXTR_PRCT = ROUND(@ExpnExtrPrct * @DateDiff / 60, -3)
               ,END_TIME = @EndTime
          WHERE MBSP_FIGH_FILE_NO = @FileNo
            AND MBSP_RECT_CODE = '001'
            AND MBSP_RWNO = @MbspRwno
            AND SESN_SNID = @Snid
            AND RWNO = @SnmtRwno
            AND END_TIME IS NULL;
      END
      ELSE IF EXISTS(
         SELECT * 
           FROM Session_Meeting 
          WHERE MBSP_FIGH_FILE_NO = @FileNo
            AND MBSP_RECT_CODE = '001'
            AND MBSP_RWNO = @MbspRwno
            AND SESN_SNID = @Snid
            AND RWNO = @SnmtRwno
            AND (VALD_TYPE != @ValdType OR
                 STRT_TIME != @StrtTime)
      )
      BEGIN
         UPDATE Session_Meeting
            SET STRT_TIME = @StrtTime
               ,VALD_TYPE = @ValdType
          WHERE MBSP_FIGH_FILE_NO = @FileNo
            AND MBSP_RECT_CODE = '001'
            AND MBSP_RWNO = @MbspRwno
            AND SESN_SNID = @Snid
            AND RWNO = @SnmtRwno;
      END
      L$EndFetchC$Snmt:
      CLOSE C$Snmt;
      DEALLOCATE C$Snmt;
      
      --BEGIN
      --    -- اگر در ثبت موقت باشیم و برای نوع درخواست و متقاضی آیین نامه هزینه داری داشته باشیم درخواست را به فرم اعلام هزینه ارسال میکنیم            
      --   IF EXISTS(
      --      SELECT *
      --        FROM Request_Row Rr, Fighter F
      --       WHERE Rr.FIGH_FILE_NO = F.FILE_NO
      --         AND Rr.RQST_RQID = @Rqid
      --         AND EXISTS(
      --            SELECT *
      --              FROM dbo.VF$All_Expense_Detail(
      --               @PrvnCode, 
      --               @RegnCode, 
      --               NULL, 
      --               @RqtpCode, 
      --               @RqttCode, 
      --               NULL, 
      --               NULL, 
      --               F.Mtod_Code_Dnrm , 
      --               F.Ctgy_Code_Dnrm)
      --         )
      --   )
      --   BEGIN
      --      IF NOT EXISTS(SELECT * FROM Request WHERE RQID = @Rqid AND SSTT_MSTT_CODE = 2 AND SSTT_CODE = 2)
      --      BEGIN
      --         SELECT @X = (
      --            SELECT @Rqid '@rqid'          
      --                  ,@RqtpCode '@rqtpcode'
      --                  ,@RqttCode '@rqttcode'
      --                  ,@RegnCode '@regncode'  
      --                  ,@PrvnCode '@prvncode'
      --            FOR XML PATH('Request'), ROOT('Process')
      --         );
      --         EXEC INS_SEXP_P @X;             

      --         UPDATE Request
      --            SET SEND_EXPN = '002'
      --               ,SSTT_MSTT_CODE = 2
      --               ,SSTT_CODE = 2
      --          WHERE RQID = @Rqid;
      --     END
      --   END
      --   ELSE
      --   BEGIN
      --      UPDATE Request
      --         SET SEND_EXPN = '001'
      --            ,SSTT_MSTT_CODE = 1
      --            ,SSTT_CODE = 1
      --       WHERE RQID = @Rqid;                
            
      --      DELETE Payment_Detail 
      --       WHERE PYMT_RQST_RQID = @Rqid;          
      --      DELETE Payment
      --       WHERE RQST_RQID = @Rqid;            
      --   END  
      --END      
      COMMIT TRAN OIC_SRQT_F_T1;
   END TRY
   BEGIN CATCH
      IF (SELECT CURSOR_STATUS('global','C$Snmt')) >= -1
      BEGIN
         IF (SELECT CURSOR_STATUS('global','C$Snmt')) > -1
            CLOSE C$Snmt
         DEALLOCATE C$Snmt
      END               

      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN OIC_SRQT_F_T1;
   END CATCH;
END;
GO
