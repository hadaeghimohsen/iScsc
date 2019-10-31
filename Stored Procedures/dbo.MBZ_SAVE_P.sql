SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[MBZ_SAVE_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	/*
	   شرایط ارسال داده ها مربوط به جدول درخواست
	   1 - درخواست جدید می باشد و ستون شماره درخواست خالی می باشد
	   2 - درخواست قبلا ثبت شده و ستون شماره درخواست خالی نمی باشد
	*/
	DECLARE @ErrorMessage NVARCHAR(MAX);
	BEGIN TRAN T1;
	BEGIN TRY
	   DECLARE @Rqid     BIGINT,
	           @RqstRqid BIGINT,
	           @RqtpCode VARCHAR(3),
	           @RqttCode VARCHAR(3),
	           @RegnCode VARCHAR(3),
	           @PrvnCode VARCHAR(3);
   	
	   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT')
	         --,@RqstRqid = @X.query('//Request').value('(Request/@rqstrqid)[1]', 'BIGINT')
	         --,@RqtpCode = @X.query('//Request').value('(Request/@rqtpcode)[1]', 'VARCHAR(3)')
	         --,@RqttCode = @X.query('//Request').value('(Request/@rqttcode)[1]', 'VARCHAR(3)')
	         --,@RegnCode = @X.query('//Request').value('(Request/@regncode)[1]', 'VARCHAR(3)')
	         --,@PrvnCode = @X.query('//Request').value('(Request/@prvncode)[1]', 'VARCHAR(3)');

      DECLARE @FileNo BIGINT,@RqroRwno SMALLINT;

      DECLARE C$RQRV CURSOR FOR
         SELECT Rwno, Figh_File_No
           FROM Request_Row Rr
          WHERE Rr.Rqst_Rqid = @Rqid            
            AND Rr.Recd_Stat = '002';
      
      OPEN C$RQRV;
      NextFromRqrv:
      FETCH NEXT FROM C$RQRV INTO @RqroRwno, @FileNo;
      
      IF @@FETCH_STATUS <> 0
         GOTO EndFetchRqrv;
      
      DECLARE @StrtDate DATE
             ,@EndDate  DATE
             ,@PrntCont SMALLINT
             ,@NumbMontOfer INT
             ,@NumbOfAttnMont INT
             ,@NumbOfAttnWeek INT
             ,@AttnDayType VARCHAR(3)
             ,@SumAttnMontDnrm INT
             ,@SumAttnWeekDnrm INT
             ,@FgpbRwno INT;
      
      SELECT @StrtDate = M.STRT_DATE
            ,@EndDate  = M.END_DATE
            ,@PrntCont = M.PRNT_CONT
            ,@NumbMontOfer = M.NUMB_MONT_OFER
            ,@NumbOfAttnMont = M.NUMB_OF_ATTN_MONT
            ,@NumbOfAttnWeek = M.NUMB_OF_ATTN_WEEK
            ,@AttnDayType = M.ATTN_DAY_TYPE
            ,@SumAttnMontDnrm = M.SUM_ATTN_MONT_DNRM
            ,@SumAttnWeekDnrm = m.SUM_ATTN_WEEK_DNRM
            ,@FgpbRwno = M.FGPB_RWNO_DNRM
        FROM Member_Ship M
       WHERE M.FIGH_FILE_NO = @fileno
         AND M.RQRO_RQST_RQID = @Rqid
         AND RECT_CODE = '001';
      
      IF @PrntCont = 0
      BEGIN
         SET @ErrorMessage = N'کارت عضویت هنرجوی ردیف ' + CAST(@RqroRwno AS VARCHAR(3)) + N' چاپ نشده!';
         RAISERROR(@ErrorMessage, 16, 1);
      END
      
      IF NOT EXISTS(SELECT * FROM Member_Ship WHERE RQRO_RQST_RQID = @Rqid AND RQRO_RWNO = @RqroRwno AND FIGH_FILE_NO = @FileNo AND RECT_CODE = '004')
         EXEC INS_MBSP_P @Rqid, @RqroRwno, @FileNo, '004', '005', @StrtDate, @EndDate, @PrntCont, @NumbMontOfer, @NumbOfAttnMont, @NumbOfAttnWeek, @AttnDayType;
      ELSE
         EXEC UPD_MBSP_P @Rqid, @RqroRwno, @FileNo, '004', '005', @StrtDate, @EndDate, @PrntCont, @NumbMontOfer, @NumbOfAttnMont, @NumbOfAttnWeek, @AttnDayType;
      
      -- 1395/05/09 * برای اینکه تعداد جلساتی که در باشگاه حضور پیدا کرده
      UPDATE dbo.Member_Ship
         SET NUMB_OF_ATTN_MONT = NULL
            ,SUM_ATTN_MONT_DNRM = NULL --@SumAttnMontDnrm
            ,SUM_ATTN_WEEK_DNRM = NULL -- @SumAttnWeekDnrm
            ,FGPB_RWNO_DNRM = NULL -- @FgpbRwno
            ,FGPB_RECT_CODE_DNRM = NULL -- '004'
       WHERE RQRO_RQST_RQID = @Rqid
         AND RQRO_RWNO = @RqroRwno
         AND FIGH_FILE_NO = @FileNo
         AND RECT_CODE = '004';      
      
      GOTO NextFromRqrv;
      EndFetchRqrv:
      CLOSE C$RQRV;
      DEALLOCATE C$RQRV;          
	   
      IF (SELECT COUNT(*)
           FROM Request_Row Rr
          WHERE Rr.RQST_RQID = @Rqid            
            AND Rr.RECD_STAT = '002') = 
          (SELECT COUNT(*)
           FROM Member_Ship T
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
      
      DECLARE @MinMbspRwno SMALLINT,
              @MaxMbspRwno SMALLINT;
              
      SELECT  @MinMbspRwno = MIN(RWNO), @MaxMbspRwno = MAX(RWNO)      
        FROM dbo.Member_Ship
       WHERE FIGH_FILE_NO = @FileNo
         AND RECT_CODE = '004'
         AND VALD_TYPE = '002'
         AND CAST(GETDATE() AS DATE) BETWEEN CAST(STRT_DATE AS DATE) AND CAST(END_DATE AS DATE)
         AND (NUMB_OF_ATTN_MONT = 0 OR NUMB_OF_ATTN_MONT > SUM_ATTN_MONT_DNRM);
      
      -- 1396/11/06 * بدست آوردن گزینه هایی که در بلوکه کردن دخیل هستن
      DECLARE C$Mbsp CURSOR FOR 
         SELECT RWNO, FGPB_RWNO_DNRM
           FROM dbo.Member_Ship
          WHERE FIGH_FILE_NO = @FileNo
            AND RECT_CODE = '004'
            AND VALD_TYPE = '002'
            AND CAST(GETDATE() AS DATE) BETWEEN CAST(STRT_DATE AS DATE) AND CAST(END_DATE AS DATE)
            AND (NUMB_OF_ATTN_MONT = 0 OR NUMB_OF_ATTN_MONT > SUM_ATTN_MONT_DNRM)
            AND RWNO BETWEEN @MinMbspRwno AND @MaxMbspRwno;
      
      DECLARE @MbspRwno SMALLINT;
      
      OPEN [C$Mbsp];
      L$Loop_Mbsp:
      FETCH [C$Mbsp] INTO @MbspRwno, @FgpbRwno;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndLoop_Mbsp;
      
      DECLARE @Xt XML;
      SELECT @Xt = (
         SELECT @Rqid AS '@rqstrqid'
               ,'009' AS '@rqtpcode'
               ,'004' AS '@rqttcode'
               ,f.REGN_CODE AS '@regncode'
               ,f.REGN_PRVN_CODE AS '@prvncode'
               ,(
                  SELECT f.FILE_NO AS '@fileno'
                        ,(
                           SELECT m.Strt_Date AS '@strtdate'
                                 ,DATEADD(DAY, DATEDIFF(DAY, @StrtDate, @EndDate), m.End_Date) AS '@enddate'
                                 ,1 AS '@prntcont'
                                 ,m.NUMB_MONT_OFER AS '@numbmontofer'
                                 ,m.NUMB_OF_ATTN_MONT AS '@numbofattnmont'
                                 ,m.NUMB_OF_ATTN_WEEK AS '@numbofattnweek'
                                 ,m.attn_day_Type AS '@attndaytype'
                              FOR XML PATH('Member_Ship'), TYPE                           
                        )
                     FOR XML PATH('Request_Row'), TYPE                  
               )
           FROM dbo.Fighter f, dbo.Member_Ship m
          WHERE f.FILE_NO = m.FIGH_FILE_NO
            --AND f.MBSP_RWNO_DNRM = m.RWNO
            AND m.RWNO = @MbspRwno
            AND F.FILE_NO = @FileNo
            AND m.RECT_CODE = '004'
            FOR XML PATH('Request'), ROOT('Process'), TYPE
      );      
      EXEC UCC_RQST_P @Xt;
      
      SELECT @Rqid = R.RQID
        FROM Request R
       WHERE R.RQST_RQID = @Rqid
         AND R.RQST_STAT = '001'
         AND R.RQTP_CODE = '009'
         AND R.RQTT_CODE = '004';
      
      -- 1395/05/09 * برای اینکه تعداد جلساتی که در باشگاه حضور پیدا کرده
      UPDATE dbo.Member_Ship
         SET SUM_ATTN_MONT_DNRM = @SumAttnMontDnrm
            ,SUM_ATTN_WEEK_DNRM = @SumAttnWeekDnrm
            ,FGPB_RWNO_DNRM = @FgpbRwno
            ,FGPB_RECT_CODE_DNRM = '004'
       WHERE RQRO_RQST_RQID = @Rqid
         AND RQRO_RWNO = @RqroRwno
         AND FIGH_FILE_NO = @FileNo
         AND RECT_CODE = '001';      

      
      SELECT @Xt = (
         SELECT @Rqid AS '@rqid'
               ,'009' AS '@rqtpcode'
               ,'004' AS '@rqttcode'
               ,f.REGN_CODE AS '@regncode'
               ,f.REGN_PRVN_CODE AS '@prvncode'
               ,(
                  SELECT f.FILE_NO AS '@fileno'
                        ,(
                           SELECT m.Strt_Date AS '@strtdate'
                                 ,m.End_Date AS '@enddate'
                                 ,m.Prnt_Cont AS '@prntcont'
                                 ,m.NUMB_MONT_OFER AS '@numbmontofer'
                                 ,m.NUMB_OF_ATTN_MONT AS '@numbofattnmont'
                                 ,m.NUMB_OF_ATTN_WEEK AS '@numbofattnweek'
                                 ,m.attn_day_Type AS '@attndaytype'
                              FOR XML PATH('Member_Ship'), TYPE                           
                        )
                     FOR XML PATH('Request_Row'), TYPE                  
               )
           FROM dbo.Fighter f, dbo.Member_Ship m
          WHERE f.FILE_NO = m.FIGH_FILE_NO
            --AND f.MBSP_RWNO_DNRM = m.RWNO
            AND m.RQRO_RQST_RQID = @Rqid
            AND m.RECT_CODE = '001'
            FOR XML PATH('Request'), ROOT('Process'), TYPE
      );      
      EXEC UCC_SAVE_P @Xt;

      -- 1395/05/09 * برای اینکه تعداد جلساتی که در باشگاه حضور پیدا کرده
      UPDATE dbo.Member_Ship
         SET SUM_ATTN_MONT_DNRM = @SumAttnMontDnrm
            ,SUM_ATTN_WEEK_DNRM = @SumAttnWeekDnrm
            ,FGPB_RWNO_DNRM = @FgpbRwno
            ,FGPB_RECT_CODE_DNRM = '004'
       WHERE RQRO_RQST_RQID = @Rqid
         AND RQRO_RWNO = @RqroRwno
         AND FIGH_FILE_NO = @FileNo
         AND RECT_CODE = '004';
      
      UPDATE dbo.Member_Ship
         SET VALD_TYPE = '001'
       WHERE FIGH_FILE_NO = @FileNo
         AND RECT_CODE = '004'
         AND RWNO = @MbspRwno;       
      
      GOTO L$Loop_Mbsp;
      L$EndLoop_Mbsp:
      CLOSE [C$Mbsp];
      DEALLOCATE [C$Mbsp];
      
      --DECLARE @Mbsp_Rwno INT;
      --SELECT @Mbsp_Rwno = F.MBSP_RWNO_DNRM
      --  FROM dbo.Fighter F
      -- WHERE F.FILE_NO = @FileNo;
       
      -- 1396/05/09 * اگر هنرجو از مشتریان جلسات ترکیبی باشد باید اطلاعات جداول زیر پر شود
      -- Session, Session_Metting
      --IF Exists(
      --   SELECT *
      --     FROM dbo.Session s, dbo.Member_Ship m, dbo.Fighter f
      --    WHERE f.FILE_NO = m.FIGH_FILE_NO
      --      AND (f.MBFZ_RWNO_DNRM - 1) = m.RWNO
      --      AND m.RECT_CODE = '004'
      --      AND s.MBSP_FIGH_FILE_NO = m.FIGH_FILE_NO
      --      AND s.MBSP_RECT_CODE = m.RECT_CODE
      --      AND s.MBSP_RWNO = m.RWNO
      --      AND f.FILE_NO = @FileNo
      --)
      --BEGIN
      --   DECLARE C$Sesn CURSOR FOR
      --   SELECT s.MBSP_FIGH_FILE_NO ,s.MBSP_RECT_CODE ,s.EXPN_CODE ,s.SNID ,s.SESN_TYPE ,s.TIME_WATE ,s.TOTL_SESN ,s.SUM_MEET_HELD_DNRM ,s.SUM_MEET_MINT_DNRM ,s.CARD_NUMB ,s.CBMT_CODE
      --     FROM dbo.Session s, dbo.Member_Ship m, dbo.Fighter f
      --    WHERE f.FILE_NO = m.FIGH_FILE_NO
      --      AND (f.MBFZ_RWNO_DNRM - 1) = m.RWNO
      --      AND m.RECT_CODE = '004'
      --      AND s.MBSP_FIGH_FILE_NO = m.FIGH_FILE_NO
      --      AND s.MBSP_RECT_CODE = m.RECT_CODE
      --      AND s.MBSP_RWNO = m.RWNO
      --      AND f.FILE_NO = @FileNo;
         
      --   DECLARE @MBSP_FIGH_FILE_NO BIGINT,
      --           @MBSP_RECT_CODE VARCHAR(3),
      --           --@MBSP_RWNO INT,
      --           @EXPN_CODE BIGINT,
      --           @SNID BIGINT,
      --           @SESN_TYPE VARCHAR(3),
      --           @TIME_WATE TIME,
      --           @TOTL_SESN SMALLINT,
      --           @SUM_MEET_HELD_DNRM SMALLINT ,
      --           @SUM_MEET_MINT_DNRM SMALLINT,
      --           @CARD_NUMB VARCHAR(50),
      --           @CBMT_CODE BIGINT;
         
      --   OPEN [C$Sesn];
      --   L$Loop:
      --   FETCH NEXT FROM [C$Sesn] INTO @MBSP_FIGH_FILE_NO ,@MBSP_RECT_CODE ,@EXPN_CODE ,@SNID ,@SESN_TYPE ,@TIME_WATE ,@TOTL_SESN ,@SUM_MEET_HELD_DNRM ,@SUM_MEET_MINT_DNRM ,@CARD_NUMB ,@CBMT_CODE;
         
      --   IF @@FETCH_STATUS <> 0
      --      GOTO L$EndLoop;
         
      --   DECLARE @NewSnId BIGINT = dbo.GNRT_NVID_U();
            
      --   INSERT INTO dbo.Session ( MBSP_FIGH_FILE_NO ,MBSP_RECT_CODE ,MBSP_RWNO ,EXPN_CODE ,SESN_SNID ,SNID ,SESN_TYPE ,TIME_WATE ,TOTL_SESN ,SUM_MEET_HELD_DNRM ,SUM_MEET_MINT_DNRM ,CARD_NUMB ,CBMT_CODE )
      --   VALUES (@MBSP_FIGH_FILE_NO ,@MBSP_RECT_CODE ,@MBSP_RWNO ,@EXPN_CODE ,@SNID, @NewSnId ,@SESN_TYPE ,@TIME_WATE ,@TOTL_SESN ,@SUM_MEET_HELD_DNRM ,@SUM_MEET_MINT_DNRM ,@CARD_NUMB ,@CBMT_CODE);
         
      --   DECLARE @RWNO [smallint],
	     --         @VALD_TYPE [varchar](3),
	     --         @ACTN_DATE [date] ,
	     --         @STRT_TIME [time](0),
	     --         @END_TIME [time](0) ,
	     --         @MEET_MINT_DNRM [int] ,
	     --         @NUMB_OF_GAYS [smallint] ,
	     --         @EXPN_PRIC [int] ,
	     --         @EXPN_EXTR_PRCT [int] ,
	     --         @REMN_PRIC [int] ;

      --   -- Insert Session_Metting
      --   DECLARE C$SesnMtng CURSOR FOR
      --      SELECT [EXPN_CODE], [RWNO] ,[VALD_TYPE] ,[ACTN_DATE] ,[STRT_TIME] ,[END_TIME] ,[MEET_MINT_DNRM] ,[NUMB_OF_GAYS] ,[EXPN_PRIC] ,[EXPN_EXTR_PRCT] ,[REMN_PRIC] , [CBMT_CODE]
      --        FROM dbo.Session_Meeting
      --       WHERE SESN_SNID = @SNID;
         
      --   OPEN [C$SesnMtng];
      --   L$Loop1:
      --   FETCH NEXT FROM [C$SesnMtng] INTO @EXPN_CODE, @RWNO, @VALD_TYPE, @ACTN_DATE, @STRT_TIME, @END_TIME, @MEET_MINT_DNRM, @NUMB_OF_GAYS, @EXPN_PRIC, @EXPN_EXTR_PRCT, @REMN_PRIC, @CBMT_CODE;
         
      --   IF @@FETCH_STATUS <> 00
      --      GOTO L$EndLoop1;
         
      --   INSERT INTO dbo.Session_Meeting( MBSP_FIGH_FILE_NO ,MBSP_RECT_CODE ,MBSP_RWNO ,EXPN_CODE ,SESN_SNID ,RWNO ,
      --                                    VALD_TYPE ,ACTN_DATE ,STRT_TIME ,END_TIME ,MEET_MINT_DNRM ,NUMB_OF_GAYS ,
      --                                    EXPN_PRIC ,EXPN_EXTR_PRCT ,REMN_PRIC ,CBMT_CODE )
      --   VALUES(@FileNo, '004', @Mbsp_Rwno, @EXPN_CODE, @NewSNID, 0, 
      --          @VALD_TYPE, @ACTN_DATE, @STRT_TIME, @END_TIME, @MEET_MINT_DNRM, @NUMB_OF_GAYS, 
      --          @EXPN_PRIC, @EXPN_EXTR_PRCT, @REMN_PRIC, @CBMT_CODE);
         
      --   GOTO L$Loop1;
      --   L$EndLoop1:
      --   CLOSE [C$SesnMtng];
      --   DEALLOCATE [C$SesnMtng];
         
      --   GOTO L$Loop;
      --   L$EndLoop:
      --   CLOSE [C$Sesn];
      --   DEALLOCATE [C$Sesn];
         
      --END
      
      -- 1398/06/30 * ثبت پیامک       
      DECLARE @CellPhon VARCHAR(11),
              @DadCellPhon VARCHAR(11),
              @MomCellPhon VARCHAR(11),
              @SexType VARCHAR(3),
              @FrstName NVARCHAR(250),
              @LastName NVARCHAR(250);
      
      SELECT @CellPhon = CELL_PHON_DNRM
            ,@DadCellPhon = DAD_CELL_PHON_DNRM
            ,@MomCellPhon = MOM_CELL_PHON_DNRM
            ,@SexType = SEX_TYPE_DNRM
            ,@FrstName = FRST_NAME_DNRM
            ,@LastName = LAST_NAME_DNRM
        FROM dbo.Fighter
       WHERE FILE_NO = @FileNo;
                    
      IF @CellPhon IS NOT NULL AND LEN(@CellPhon) != 0 
      BEGIN
         DECLARE @MsgbStat VARCHAR(3)
                ,@MsgbText NVARCHAR(MAX)
                ,@ClubName NVARCHAR(250)
                ,@InsrCnamStat VARCHAR(3)
                ,@InsrFnamStat VARCHAR(3)
                ,@LineType VARCHAR(3)
                ,@SendInfo VARCHAR(3)
                ,@AmntType VARCHAR(3)
                ,@AmntTypeDesc NVARCHAR(255)
                ,@MesgInfo NVARCHAR(MAX)
                ,@MinNumbDayRmnd int;
                
         SELECT @MsgbStat = STAT
               ,@MsgbText = MSGB_TEXT
               ,@ClubName = CLUB_NAME
               ,@InsrCnamStat = INSR_CNAM_STAT
               ,@InsrFnamStat = INSR_FNAM_STAT
               ,@LineType = LINE_TYPE
               ,@SendInfo = SEND_INFO
           FROM dbo.Message_Broadcast
          WHERE MSGB_TYPE = '013';
         
         IF @MsgbStat = '002' 
         BEGIN
            IF @InsrFnamStat = '002'
               SET @MsgbText = (SELECT DOMN_DESC FROM dbo.[D$SXDC] WHERE VALU = @SexType) + N' ' + @FrstName + N' ' + @LastName + N' ' + @MsgbText;
            
            IF @SendInfo = '002'
            BEGIN            
               SELECT @MesgInfo =                       
                      N'اطلاعات بلاک دوره شما به شرح زیر میباشد' + CHAR(10) +                       
                      N'شروع بلاک دوره ' + dbo.GET_MTOS_U(ms.STRT_DATE) + CHAR(10) +
                      N'پایان بلاک دوره ' + dbo.GET_MTOS_U(ms.END_DATE) + CHAR(10) 
                 FROM dbo.Request r,
                      dbo.Request_Row rr,
                      dbo.Member_Ship ms
                WHERE r.RQID = rr.RQST_RQID
                  and rr.RQST_RQID = ms.RQRO_RQST_RQID
                  AND rr.FIGH_FILE_NO = ms.FIGH_FILE_NO
                  AND ms.RECT_CODE = '004'                  
                  AND r.RQID = @Rqid; 
                                   
               SET @MsgbText = @MsgbText + CHAR(10) + @MesgInfo;
            END;

            IF @InsrCnamStat = '002'
               SET @MsgbText = @MsgbText + N' ' + @ClubName;
            
            DECLARE @XMsg XML;
            SELECT @XMsg = (
               SELECT 5 AS '@subsys',
                      @LineType AS '@linetype',
                      (
                        SELECT @CellPhon AS '@phonnumb',
                               (
                                   SELECT '013' AS '@type' 
                                          ,@Rqid AS '@rfid'
                                          ,@MsgbText
                                      FOR XML PATH('Message'), TYPE 
                               ) 
                           FOR XML PATH('Contact'), TYPE
                      )
                 FOR XML PATH('Contacts'), ROOT('Process')                            
            );
            EXEC dbo.MSG_SEND_P @X = @XMsg -- xml
            
            -- ارسال پیامک به مادر
            IF @MomCellPhon IS NOT NULL
            BEGIN
               SELECT @XMsg = (
                  SELECT 5 AS '@subsys',
                         @LineType AS '@linetype',
                         (
                           SELECT @MomCellPhon AS '@phonnumb',
                                  (
                                      SELECT '013' AS '@type' 
                                             ,@Rqid AS '@rfid'
                                             ,N'مادر ' + CASE @SexType WHEN '001' THEN (N' آقا ' + @FrstName) ELSE (@FrstName + N' خانم ') END + CHAR(10) + N' اطلاعات فرزند دلبند شما با موفقیت در سامانه بلاک دوره ثبت گردید. ' + CHAR(10) + N'با آرزوی بهترین ها برای شما خانواده ' + @LastName + N' عزیز ' + CHAR(10) + CASE @SendInfo WHEN '002' THEN @MesgInfo ELSE N' ' END + CASE @InsrCnamStat WHEN '002' THEN @ClubName ELSE N'' END 
                                         FOR XML PATH('Message'), TYPE 
                                  ) 
                              FOR XML PATH('Contact'), TYPE
                         )
                    FOR XML PATH('Contacts'), ROOT('Process')                            
               );
               EXEC dbo.MSG_SEND_P @X = @XMsg -- xml
            END
            
            -- ارسال پیامک به پدر
            IF @DadCellPhon IS NOT NULL
            BEGIN
               SELECT @XMsg = (
                  SELECT 5 AS '@subsys',
                         @LineType AS '@linetype',
                         (
                           SELECT @DadCellPhon AS '@phonnumb',
                                  (
                                      SELECT '013' AS '@type' 
                                             ,@Rqid AS '@rfid'
                                             ,N'پدر ' + CASE @SexType WHEN '001' THEN (N' آقا ' + @FrstName) ELSE (@FrstName + N' خانم ') END + CHAR(10) + N' اطلاعات فرزند دلبند شما با موفقیت در سامانه بلاک دوره ثبت گردید. ' + CHAR(10) + N'با آرزوی بهترین ها برای شما خانواده ' + @LastName + N' عزیز ' + CHAR(10) + CASE @SendInfo WHEN '002' THEN @MesgInfo ELSE N' ' END + CASE @InsrCnamStat WHEN '002' THEN @ClubName ELSE N'' END 
                                         FOR XML PATH('Message'), TYPE 
                                  ) 
                              FOR XML PATH('Contact'), TYPE
                         )
                    FOR XML PATH('Contacts'), ROOT('Process')                            
               );
               EXEC dbo.MSG_SEND_P @X = @XMsg -- xml
            END;
            
            -- ارسال پیامک هشدار جهت تمدید مجدد
            -- بررسی اینکه پیامک هشدار فعال میباشد یا خیر
            IF EXISTS(SELECT * FROM dbo.Message_Broadcast WHERE MSGB_TYPE = '014' AND STAT = '002')
            BEGIN
               SELECT @MsgbStat = STAT
                     ,@MsgbText = MSGB_TEXT
                     ,@ClubName = CLUB_NAME
                     ,@InsrCnamStat = INSR_CNAM_STAT
                     ,@InsrFnamStat = INSR_FNAM_STAT
                     ,@MinNumbDayRmnd = MIN_NUMB_DAY_RMND
                 FROM dbo.Message_Broadcast
                WHERE MSGB_TYPE = '014';
               
               IF @MsgbStat = '002' 
               BEGIN
                  IF @InsrFnamStat = '002'
                     SET @MsgbText = (SELECT DOMN_DESC FROM dbo.[D$SXDC] WHERE VALU = @SexType) + N' ' + @FrstName + N' ' + @LastName + N' ' + @MsgbText;
                  
                  IF @InsrCnamStat = '002'
                     SET @MsgbText = @MsgbText + N' ' + @ClubName;
                  
                  DECLARE @ExpireDay INT = DATEDIFF(DAY, GETDATE(), @EndDate)
                         ,@i INT = 1;
                  
                  IF @i < @ExpireDay
                  BEGIN
                  --DECLARE @XMsg XML;
                  SELECT @XMsg = (
                     SELECT 5 AS '@subsys',
                            '001' AS '@linetype',
                            (
                              SELECT @CellPhon AS '@phonnumb',
                                     (
                                         SELECT '014' AS '@type' 
                                                ,@Rqid AS '@rfid'
                                                ,DATEADD(DAY, @i, GETDATE() ) AS '@actndate'
                                                ,CASE @SexType WHEN '001' THEN (N' آقای ' + @FrstName) ELSE (@FrstName + N' خانم ') END + @LastName + CHAR(10) + CAST(@i AS NVARCHAR(3)) + N' روز از تعداد روز بلاک دوره شما باقیمانده است ' + CHAR(10) + N' تاریخ اتمام بلاک دوره ' + dbo.GET_MTOS_U(@EndDate) + CHAR(10) + CASE @InsrCnamStat WHEN '002' THEN @ClubName ELSE N'' END 
                                            FOR XML PATH('Message'), TYPE 
                                     ) 
                                 FOR XML PATH('Contact'), TYPE
                            ),
                            (
                              SELECT @DadCellPhon AS '@phonnumb',
                                     (
                                       SELECT '014' AS '@type' 
                                              ,@Rqid AS '@rfid'
                                              ,DATEADD(DAY, @i, GETDATE() ) AS '@actndate'
                                              ,N'پدر ' + CASE @SexType WHEN '001' THEN (N' آقا ' + @FrstName) ELSE (@FrstName + N' خانم ') END + CHAR(10) + CAST(@i AS NVARCHAR(3)) + N' روز از تعداد روز بلاک دوره فرزند شما باقیمانده است ' + CHAR(10) + N'با آرزوی بهترین ها برای شما خانواده ' + @LastName + N' عزیز ' + CHAR(10) + N' تاریخ اتمام بلاک دوره ' + dbo.GET_MTOS_U(@EndDate) + CHAR(10) + CASE @InsrCnamStat WHEN '002' THEN @ClubName ELSE N'' END 
                                          FOR XML PATH('Message'), TYPE 
                                     ) 
                                 FOR XML PATH('Contact'), TYPE
                            ),
                            (
                              SELECT @MomCellPhon AS '@phonnumb',
                                     (
                                         SELECT '014' AS '@type' 
                                                ,@Rqid AS '@rfid'
                                                ,DATEADD(DAY, @i, @EndDate ) AS '@actndate'
                                                ,N'مادر ' + CASE @SexType WHEN '001' THEN (N' آقا ' + @FrstName) ELSE (@FrstName + N' خانم ') END + CHAR(10) + CAST(@i AS NVARCHAR(3)) + N' روز از تعداد روز بلاک دوره فرزند شما باقیمانده است ' + CHAR(10) + N'با آرزوی بهترین ها برای شما خانواده ' + @LastName + N' عزیز ' + CHAR(10) + N' تاریخ اتمام دوره ' + dbo.GET_MTOS_U(@EndDate) + CHAR(10) + CASE @InsrCnamStat WHEN '002' THEN @ClubName ELSE N'' END 
                                            FOR XML PATH('Message'), TYPE 
                                     ) 
                                 FOR XML PATH('Contact'), TYPE
                            )
                       FOR XML PATH('Contacts'), ROOT('Process')                            
                  );
                  EXEC dbo.MSG_SEND_P @X = @XMsg -- xml
                  
                  SET @i += 1;
                  END -- IF @i <= @ExpireDay
               END;
            END;
            
            -- ارسال پیامک هشدار جهت تمدید مجدد
            -- بررسی اینکه پیامک هشدار فعال میباشد یا خیر
            IF EXISTS(SELECT * FROM dbo.Message_Broadcast WHERE MSGB_TYPE = '015' AND STAT = '002')
            BEGIN
               SELECT @MsgbStat = STAT
                     ,@MsgbText = MSGB_TEXT
                     ,@ClubName = CLUB_NAME
                     ,@InsrCnamStat = INSR_CNAM_STAT
                     ,@InsrFnamStat = INSR_FNAM_STAT
                     ,@MinNumbDayRmnd = MIN_NUMB_DAY_RMND
                 FROM dbo.Message_Broadcast
                WHERE MSGB_TYPE = '015';
               
               IF @MsgbStat = '002' 
               BEGIN
                  IF @InsrFnamStat = '002'
                     SET @MsgbText = (SELECT DOMN_DESC FROM dbo.[D$SXDC] WHERE VALU = @SexType) + N' ' + @FrstName + N' ' + @LastName + N' ' + @MsgbText;
                  
                  IF @InsrCnamStat = '002'
                     SET @MsgbText = @MsgbText + N' ' + @ClubName;
                  
                  --DECLARE @XMsg XML;
                  SELECT @XMsg = (
                     SELECT 5 AS '@subsys',
                            '001' AS '@linetype',
                            (
                              SELECT @CellPhon AS '@phonnumb',
                                     (
                                         SELECT '014' AS '@type' 
                                                ,@Rqid AS '@rfid'
                                                ,@EndDate AS '@actndate'
                                                ,CASE @SexType WHEN '001' THEN (N' آقای ' + @FrstName) ELSE (@FrstName + N' خانم ') END + @LastName + CHAR(10) + N' بلاک دوره شما به پایان رسیده ' + CHAR(10) + N' تاریخ اتمام بلاک دوره ' + dbo.GET_MTOS_U(@EndDate) + CHAR(10) + CASE @InsrCnamStat WHEN '002' THEN @ClubName ELSE N'' END 
                                            FOR XML PATH('Message'), TYPE 
                                     ) 
                                 FOR XML PATH('Contact'), TYPE
                            ),
                            (
                              SELECT @DadCellPhon AS '@phonnumb',
                                     (
                                       SELECT '014' AS '@type' 
                                              ,@Rqid AS '@rfid'
                                              ,@EndDate AS '@actndate'
                                              ,N'پدر ' + CASE @SexType WHEN '001' THEN (N' آقا ' + @FrstName) ELSE (@FrstName + N' خانم ') END + CHAR(10) + N' بلاک دوره فرزند شما به پایان رسیده است ' + CHAR(10) + N'با آرزوی بهترین ها برای شما خانواده ' + @LastName + N' عزیز ' + CHAR(10) + N' تاریخ اتمام بلاک دوره ' + dbo.GET_MTOS_U(@EndDate) + CHAR(10) + CASE @InsrCnamStat WHEN '002' THEN @ClubName ELSE N'' END 
                                          FOR XML PATH('Message'), TYPE 
                                     ) 
                                 FOR XML PATH('Contact'), TYPE
                            ),
                            (
                              SELECT @MomCellPhon AS '@phonnumb',
                                     (
                                         SELECT '014' AS '@type' 
                                                ,@Rqid AS '@rfid'
                                                ,@EndDate AS '@actndate'
                                                ,N'مادر ' + CASE @SexType WHEN '001' THEN (N' آقا ' + @FrstName) ELSE (@FrstName + N' خانم ') END + CHAR(10) + N' بلاک دوره فرزنده شما به پایان رسیده است ' + CHAR(10) + N'با آرزوی بهترین ها برای شما خانواده ' + @LastName + N' عزیز ' + CHAR(10) + N' تاریخ اتمام دوره ' + dbo.GET_MTOS_U(@EndDate) + CHAR(10) + CASE @InsrCnamStat WHEN '002' THEN @ClubName ELSE N'' END 
                                            FOR XML PATH('Message'), TYPE 
                                     ) 
                                 FOR XML PATH('Contact'), TYPE
                            )
                       FOR XML PATH('Contacts'), ROOT('Process')                            
                  );
                  EXEC dbo.MSG_SEND_P @X = @XMsg -- xml
                  
               END;
            END;
            
         END;
      END;

      
      COMMIT TRAN T1;
      RETURN 0;
   END TRY
   BEGIN CATCH
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T1;
      RETURN -1;
   END CATCH; 
END
GO
