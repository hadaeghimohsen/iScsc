CREATE TABLE [dbo].[Attendance]
(
[CLUB_CODE] [bigint] NOT NULL,
[FIGH_FILE_NO] [bigint] NOT NULL,
[ATTN_DATE] [date] NOT NULL,
[CODE] [bigint] NOT NULL,
[RWNO] [int] NULL,
[MBSP_RWNO_DNRM] [smallint] NULL,
[MBSP_RECT_CODE_DNRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Attendance_MBSP_RECT_CODE_DNRM] DEFAULT ('004'),
[COCH_FILE_NO] [bigint] NULL,
[ATTN_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Attendance_ATTN_TYPE] DEFAULT ('001'),
[ENTR_TIME] [time] (0) NULL,
[EXIT_TIME] [time] (0) NULL,
[MUST_EXIT_TIME_DNRM] [time] (0) NULL,
[TOTL_SESN] [smallint] NULL CONSTRAINT [DF_Attendance_TOTL_SESN] DEFAULT ((1)),
[ATTN_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Attendance_ATTN_STAT] DEFAULT ('002'),
[DERS_NUMB] [int] NULL,
[NAME_DNRM] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CELL_PHON_DNRM] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FGPB_TYPE_DNRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CBMT_CODE_DNRM] [bigint] NULL,
[MTOD_CODE_DNRM] [bigint] NULL,
[CTGY_CODE_DNRM] [bigint] NULL,
[IMAG_RCDC_RCID_DNRM] [bigint] NULL,
[IMAG_RWNO_DNRM] [smallint] NULL,
[FNGR_PRNT_DNRM] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DEBT_DNRM] [bigint] NULL,
[BUFE_DEBT_DNRM] [bigint] NULL,
[MBSP_STRT_DATE_DNRM] [date] NULL,
[MBSP_END_DATE_DNRM] [date] NULL,
[BRTH_DATE_DNRM] [date] NULL,
[NUMB_OF_ATTN_MONT] [int] NULL,
[SUM_ATTN_MONT_DNRM] [int] NULL,
[MBCO_RWNO_DNRM] [smallint] NULL,
[SESN_SNID_DNRM] [bigint] NULL,
[ATTN_DESC] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GLOB_CODE_DNRM] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PRNT_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Attendance_PRNT_STAT] DEFAULT ('001'),
[PRNT_CONT] [int] NULL CONSTRAINT [DF_Attendance_PRNT_CONT] DEFAULT ((0)),
[RCPT_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PMEX_CODE] [bigint] NULL,
[ATTN_SYS_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SEX_TYPE_DNRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SEND_MESG_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RTNG_NUMB] [smallint] NULL,
[OWNR_CBMT_CODE_DNRM] [bigint] NULL,
[NUMB_OPEN_DNRM] [int] NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL
) ON [BLOB] TEXTIMAGE_ON [BLOB]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AINS_ATTN] ON [dbo].[Attendance]
    AFTER INSERT
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
  SET NOCOUNT ON;
 
-- Insert statements for trigger here
  MERGE dbo.Attendance T
  USING
      ( SELECT    i.CLUB_CODE ,
                  i.FIGH_FILE_NO ,
                  i.ATTN_DATE ,
                  i.CODE ,
                  f.MBCO_RWNO_DNRM ,
                  m.NUMB_OF_ATTN_MONT ,
                  m.SUM_ATTN_MONT_DNRM ,
                  f.BRTH_DATE_DNRM ,
                  m.RWNO AS MBSP_RWNO_DNRM ,
                  f.NAME_DNRM ,
                  f.CELL_PHON_DNRM ,
                  fp.[TYPE] AS FGPB_TYPE_DNRM ,
                  ISNULL(fp.MTOD_CODE, i.MTOD_CODE_DNRM) AS MTOD_CODE_DNRM ,
                  ISNULL(fp.CTGY_CODE, ISNULL(i.CTGY_CODE_DNRM, (SELECT TOP 1 code FROM dbo.Category_Belt WHERE MTOD_CODE = fp.MTOD_CODE AND CTGY_STAT = '002'))) AS CTGY_CODE_DNRM ,
                  --ISNULL(fp.CTGY_CODE, i.CTGY_CODE_DNRM) AS CTGY_CODE_DNRM ,
                  f.IMAG_RCDC_RCID_DNRM ,
                  f.IMAG_RWNO_DNRM ,
                  f.FNGR_PRNT_DNRM ,
                  f.DEBT_DNRM ,
                  --f.BUFE_DEBT_DNTM ,
                  0 AS BUFE_DEBT_DNTM ,
                  m.STRT_DATE AS MBSP_STRT_DATE ,
                  m.END_DATE AS MBSP_END_DATE ,
                  i.ATTN_TYPE ,
                  i.ATTN_DESC ,
                  fp.CBMT_CODE ,
                  fp.GLOB_CODE ,
                  --fp.FMLY_NUMB ,
                  f.SEX_TYPE_DNRM
                  --DATEADD(MINUTE, cm.CLAS_TIME, GETDATE()) AS MUST_EXIT_TIME_DNRM
        FROM      INSERTED i ,
                  dbo.Fighter f ,
                  --dbo.Club_Method cm,
                  dbo.Fighter_Public fp
                  LEFT OUTER JOIN dbo.Member_Ship m ON m.FIGH_FILE_NO = fp.FIGH_FILE_NO
                                                       AND m.FGPB_RWNO_DNRM = fp.RWNO
                                                       AND m.FGPB_RECT_CODE_DNRM = '004'
                                                       AND m.RECT_CODE = '004'                        
        WHERE     i.FIGH_FILE_NO = f.FILE_NO
                  AND f.FILE_NO = fp.FIGH_FILE_NO
                  AND m.RWNO = i.MBSP_RWNO_DNRM
                  AND fp.RECT_CODE = '004'
                  --AND fp.CBMT_CODE = cm.CODE
      ) S
  ON ( T.CLUB_CODE = S.CLUB_CODE
       AND T.FIGH_FILE_NO = S.FIGH_FILE_NO
       AND CAST(T.ATTN_DATE AS DATE) = CAST(S.ATTN_DATE AS DATE)
       AND T.CODE = S.CODE
     )
  WHEN MATCHED THEN
      UPDATE SET
              T.CRET_BY = UPPER(SUSER_NAME()) ,
              T.CRET_DATE = GETDATE(),
              T.ENTR_TIME = CAST(GETDATE() AS TIME(0)) ,
              T.RWNO = (SELECT ISNULL(MAX(a.RWNO), 0) + 1 FROM dbo.Attendance a WHERE a.ATTN_DATE = s.ATTN_DATE),
              /*T.MBSP_RECT_CODE_DNRM = CASE WHEN S.FGPB_TYPE_DNRM NOT IN ( '002' )
                                           THEN '004'
                                           ELSE NULL
                                      END ,
              T.MBSP_RWNO_DNRM = S.MBSP_RWNO_DNRM ,*/
              T.NAME_DNRM = S.NAME_DNRM ,
              T.CELL_PHON_DNRM = S.CELL_PHON_DNRM ,
              T.FGPB_TYPE_DNRM = S.FGPB_TYPE_DNRM ,
              T.MTOD_CODE_DNRM = S.MTOD_CODE_DNRM ,
              T.CTGY_CODE_DNRM = S.CTGY_CODE_DNRM ,
              T.IMAG_RCDC_RCID_DNRM = S.IMAG_RCDC_RCID_DNRM ,
              T.IMAG_RWNO_DNRM = S.IMAG_RWNO_DNRM ,
              T.FNGR_PRNT_DNRM = S.FNGR_PRNT_DNRM ,
              T.DEBT_DNRM = S.DEBT_DNRM ,
              T.BUFE_DEBT_DNRM = S.BUFE_DEBT_DNTM ,
              T.MBSP_STRT_DATE_DNRM = S.MBSP_STRT_DATE ,
              T.MBSP_END_DATE_DNRM = S.MBSP_END_DATE ,
              T.BRTH_DATE_DNRM = S.BRTH_DATE_DNRM ,
              T.NUMB_OF_ATTN_MONT = S.NUMB_OF_ATTN_MONT ,
              T.SUM_ATTN_MONT_DNRM = CASE WHEN S.FGPB_TYPE_DNRM NOT IN (
                                               '002', '003' )
                                               AND S.ATTN_TYPE != '008'
                                          THEN ISNULL(S.SUM_ATTN_MONT_DNRM,
                                                      0) + CASE WHEN s.ATTN_TYPE NOT IN ('006', '008', '009') THEN 1 ELSE 0 END
                                          WHEN S.FGPB_TYPE_DNRM NOT IN (
                                               '002', '003' )
                                               AND S.ATTN_TYPE = '008'
                                          THEN ISNULL(S.SUM_ATTN_MONT_DNRM,
                                                      0)
                                          ELSE NULL
                                     END ,
              T.MBCO_RWNO_DNRM = S.MBCO_RWNO_DNRM ,
              T.CBMT_CODE_DNRM = S.CBMT_CODE ,
              T.GLOB_CODE_DNRM = S.GLOB_CODE ,
              --T.FMLY_NUMB_DNRM = S.FMLY_NUMB ,
              T.SEX_TYPE_DNRM = S.SEX_TYPE_DNRM ,
              --T.MUST_EXIT_TIME_DNRM = S.MUST_EXIT_TIME_DNRM,
              T.ATTN_DESC = CASE WHEN S.ATTN_TYPE = '007'
                                 THEN N'ثبت جلسه حضوری با همراه با کسر جلسه از اعضا'
                                 WHEN S.ATTN_TYPE = '008'
                                 THEN N'ثبت جلسه حضوری با همراه بدون کسر جلسه از اعضا'
                                 ELSE S.ATTN_DESC
                            END;

  DECLARE @MbspRwno SMALLINT;
  SELECT  @MbspRwno = Inserted.MBSP_RWNO_DNRM
  FROM    Inserted;
    
-- ثبت جلسه برای هنرجویان عادی
-- در جدول عضویت مشترکین
  IF EXISTS ( SELECT  *
              FROM    Fighter F ,
                      Inserted I
              WHERE   F.FILE_NO = I.FIGH_FILE_NO
                      AND F.FGPB_TYPE_DNRM IN ( '001', '005', '006' )
                      AND F.CONF_STAT = '002'
                      AND I.ATTN_TYPE NOT IN ( '006','008', '009' ) /* همراهانی که بدون کسر جلسه وارد میشوند نیازی به تغییر تعداد جلسات نیست */)
      BEGIN
		-- اگر برای هنرجو تعداد جلسه مشخص شده باشد
          IF EXISTS ( SELECT  *
                      FROM    dbo.Fighter f ,
                              dbo.Member_Ship m ,
                              Attendance A ,
                              INSERTED i
                      WHERE   f.FILE_NO = m.FIGH_FILE_NO
                              --AND f.MBSP_RWNO_DNRM = m.RWNO
                              AND m.RWNO = @MbspRwno
                              AND m.RECT_CODE = '004'
                              AND A.FIGH_FILE_NO = m.FIGH_FILE_NO
                              AND A.MBSP_RWNO_DNRM = m.RWNO
                              AND A.MBSP_RECT_CODE_DNRM = m.RECT_CODE
                              AND A.FIGH_FILE_NO = i.FIGH_FILE_NO
                              -- 1403/12/03
                              AND a.ATTN_TYPE NOT IN ('006', '008', '009')
                              AND ( ( ISNULL(m.NUMB_OF_ATTN_MONT, 0) >= 1
                                      AND ISNULL(m.NUMB_OF_ATTN_MONT, 0) > ISNULL(m.SUM_ATTN_MONT_DNRM,
                                                        0)
                                    )
                                    OR ( ISNULL(m.NUMB_OF_ATTN_MONT, 0) = 0 )
                                  ) )
              BEGIN         
                  UPDATE  dbo.Member_Ship
                     SET  SUM_ATTN_MONT_DNRM = ISNULL(SUM_ATTN_MONT_DNRM, 0) + 1
                   WHERE  RWNO = @MbspRwno
                          AND RECT_CODE = '004'
                          AND EXISTS ( SELECT *
                                       FROM   INSERTED I ,
                                              Attendance A ,
                                              dbo.Method m
                                       WHERE  dbo.Member_Ship.FIGH_FILE_NO = A.FIGH_FILE_NO
                                              AND dbo.Member_Ship.RWNO = A.MBSP_RWNO_DNRM
                                              AND dbo.Member_Ship.RECT_CODE = A.MBSP_RECT_CODE_DNRM
                                              AND A.FIGH_FILE_NO = I.FIGH_FILE_NO
                                              AND dbo.Member_Ship.RECT_CODE = '004'
                                              AND A.MTOD_CODE_DNRM = m.CODE
                                              AND CAST(A.ATTN_DATE AS DATE) = CAST(I.ATTN_DATE AS DATE)
                                              AND A.ENTR_TIME IS NOT NULL
                                              -- 1403/12/03
                                              AND a.ATTN_TYPE NOT IN ('006', '008', '009') 
                                              AND ( ( A.ATTN_TYPE <> '002'
                                                      AND A.EXIT_TIME IS NULL
                                                    )
                                                    OR ( A.ATTN_TYPE <> '002'
                                                        AND A.EXIT_TIME IS NOT NULL
                                                        AND m.CHCK_ATTN_ALRM = '002'
                                                       )
                                                    OR ( A.ATTN_TYPE = '002'
                                                        -- 1397/09/22 * اگر غیبت ثبت شود از تعداد جلسات کم شود
                                                        --AND A.EXIT_TIME IS NOT NULL
                                                        AND a.EXIT_TIME IS NULL
                                                       )
                                                  ) );
				
			-- اگر گزینه ثبت نام مشارکتی در میان باشد آن دسته از افرادی که شماره پرسنلی یکسانی دارند باید یک جلسه از آنها هم کم شود
              IF EXISTS(
                  SELECT * 
                    FROM dbo.Settings s, 
                         Inserted i, 
                         dbo.Attendance a, 
                         dbo.Club_Method cm, 
                         dbo.Method m 
                   WHERE a.CODE = i.CODE 
                     AND a.CLUB_CODE = s.CLUB_CODE 
                     AND cm.CLUB_CODE = s.CLUB_CODE 
                     AND a.CBMT_CODE_DNRM = cm.CODE 
                     AND m.CODE = cm.MTOD_CODE 
                     AND s.SHAR_MBSP_STAT = '002' 
                     AND ISNULL(a.GLOB_CODE_DNRM, '') != '' 
                     AND m.CHCK_ATTN_ALRM = '002'
                     -- 1403/12/03 
                     AND I.ATTN_TYPE NOT IN ( '006', '008', '009' ) /* همراهانی که بدون کسر جلسه وارد میشوند نیازی به تغییر تعداد جلسات نیست */)
                 BEGIN
				      UPDATE  ms
			   	      SET  ms.SUM_ATTN_MONT_DNRM = ISNULL(ms.SUM_ATTN_MONT_DNRM, 0) + 1
				        FROM  dbo.Member_Ship ms, dbo.Fighter_Public fp, Attendance A , INSERTED I , dbo.Method m
			          WHERE A.FIGH_FILE_NO = I.FIGH_FILE_NO
			            AND a.CODE = i.CODE
				         AND I.ATTN_STAT = '002' -- حضوری فعال
				         AND ms.RECT_CODE = '004' -- رکورد نهایی شده						   
				         AND ms.FIGH_FILE_NO != a.FIGH_FILE_NO -- کاری به فرد جاری نداریم و دنبال مابقی افراد با کد مالی یکسان هستیم
				         AND ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
				         AND ms.FGPB_RWNO_DNRM = fp.RWNO
				         AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
				         AND fp.GLOB_CODE = a.GLOB_CODE_DNRM -- افرادی که داری کد پرسنلی یکسان هستند
				         AND fp.MTOD_CODE = a.MTOD_CODE_DNRM -- به دنبال ورزش مشارکتی
				         AND ms.VALD_TYPE = '002' 
				         AND a.MTOD_CODE_DNRM = m.CODE
				         AND m.CHCK_ATTN_ALRM = '002' -- ورزش مشارکتی 
				         -- 1403/12/03
				         AND a.ATTN_TYPE NOT IN ('006', '008', '009')
				         AND ISNULL(ms.NUMB_OF_ATTN_MONT, 0) > 0
				         AND ISNULL(Ms.NUMB_OF_ATTN_MONT, 0) > ISNULL(Ms.SUM_ATTN_MONT_DNRM, 0) /*- 1*/
				         AND CAST(a.ATTN_DATE AS DATE) BETWEEN CAST(STRT_DATE AS DATE) AND CAST(END_DATE AS DATE);
                 END;						                                    
              END;
          ELSE
              BEGIN
                  RAISERROR(N'تعداد جلسات شما به پایان رسیده لطفا برای شارژ مجدد اقدام نمایید', 16, 1);
                  RETURN;
              END;
      END;
   -- Save Deposit Amount For Good Service ONTIME
   -- 1401/11/27 * #MahsaAmini        
   -- برای ارگان هایی که میخواهیم به مشترکین آنها پورسانت لحاظ شود
   IF (SELECT COUNT(i.CODE) FROM Inserted i, dbo.Attendance a, dbo.Category_Belt c WHERE i.CODE = a.CODE AND a.CTGY_CODE_DNRM = c.CODE AND ISNULL(c.RWRD_ATTN_PRIC, 0) > 0) = 1
   BEGIN
      IF (SELECT COUNT(a.CODE) FROM dbo.Attendance a, Inserted i WHERE a.FIGH_FILE_NO = i.FIGH_FILE_NO AND a.ATTN_DATE = i.ATTN_DATE AND a.EXIT_TIME IS NOT NULL) = 0
      BEGIN 
         DECLARE @xTemp XML;
         SET @xTemp = (
             SELECT i.CODE AS '@code'
               FROM Inserted i
                FOR XML PATH('Attendance'), ROOT('OpIran')
         );
         EXEC dbo.FINL_RQST_P @X = @xTemp -- xml
      END 
   END 
END;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_ATTN] ON [dbo].[Attendance]
    AFTER UPDATE
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
   SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Attendance T
   USING ( SELECT * FROM INSERTED ) S
   ON ( T.CLUB_CODE = S.CLUB_CODE
       AND T.FIGH_FILE_NO = S.FIGH_FILE_NO
       AND CAST(T.ATTN_DATE AS DATE) = CAST(S.ATTN_DATE AS DATE)
       AND T.CODE = S.CODE )
   WHEN MATCHED THEN
      UPDATE SET
          MDFY_BY = UPPER(SUSER_NAME()) ,
          MDFY_DATE = GETDATE();
   
  -- ثبت جلسه برای هنرجویان عادی
  -- در جدول عضویت مشترکین
  IF EXISTS ( SELECT  *
              FROM    Fighter F ,
                      Inserted I ,
                      DELETED D
              WHERE   F.FILE_NO = I.FIGH_FILE_NO
                      AND I.FIGH_FILE_NO = D.FIGH_FILE_NO
                      AND I.CODE = D.CODE
                      AND I.ATTN_STAT = '001' -- الان ابطال شده
                      AND D.ATTN_STAT = '002' -- قبلا فعال بوده
                      AND F.FGPB_TYPE_DNRM IN ( '001', '005', '006' )
                      AND F.CONF_STAT = '002' )
  BEGIN
       -- 1398/06/30 * ثبت پیامک
       IF EXISTS ( SELECT  *
                   FROM    dbo.Message_Broadcast
                   WHERE   MSGB_TYPE = '022'
                           AND STAT = '002' )
       BEGIN
            DECLARE @MsgbStat VARCHAR(3) ,
                @MsgbText NVARCHAR(MAX) ,
                @XMsg XML ,
                @LineType VARCHAR(3) ,
                @Cel1Phon VARCHAR(11) ,
                @Cel2Phon VARCHAR(11) ,
                @Cel3Phon VARCHAR(11) ,
                @Cel4Phon VARCHAR(11) ,
                @Cel5Phon VARCHAR(11);
          
            SELECT  @MsgbStat = STAT ,
                    @MsgbText = MSGB_TEXT ,
                    @LineType = LINE_TYPE ,
                    @Cel1Phon = CEL1_PHON ,
                    @Cel2Phon = CEL2_PHON ,
                    @Cel3Phon = CEL3_PHON ,
                    @Cel4Phon = CEL4_PHON ,
                    @Cel5Phon = CEL5_PHON
            FROM    dbo.Message_Broadcast
            WHERE   MSGB_TYPE = '022';
      
            SELECT  @MsgbText = ( SELECT N'ابطال حضور و غیاب' + CHAR(10)
                                       + N'نام مشترک ' + a.NAME_DNRM + CHAR(10)
                                       + N'اطلاعات حضوری' + CHAR(10)
                                       + N'تاریخ ابطال حضوری : ' + dbo.GET_MTOS_U(a.ATTN_DATE) + CHAR(10)
                                       + N'کاربر : ' + UPPER(SUSER_NAME()) + CHAR(10)
                                       + N'تاریخ : ' + dbo.GET_MTST_U(GETDATE())
                                    FROM dbo.Attendance a , Inserted i
                                   WHERE i.CODE = a.CODE
                                );          
               
            IF @MsgbStat = '002'
            BEGIN
                SET @MsgbText =                               
                  dbo.GET_TEXT_F(
                     (SELECT i.FIGH_FILE_NO AS '@fileno'
                           ,i.MBSP_RWNO_DNRM AS '@mbsprwno'
                           ,@MsgbText AS '@text'
                       FROM Inserted i 
                        FOR XML PATH('TemplateToText'))).query('Result').value('.', 'NVARCHAR(4000)');
                
                    --SET @MsgbText = @XMsg.query('Result').value('.', 'NVARCHAR(4000)');
                    SELECT  @XMsg = ( SELECT    5 AS '@subsys' ,
                                                @LineType AS '@linetype' ,
                                                ( SELECT @Cel1Phon AS '@phonnumb' ,
                                                  ( SELECT '022' AS '@type' ,
                                                           @MsgbText
                                                       FOR XML PATH('Message') , TYPE )
                                                     FOR XML PATH('Contact') , TYPE ) ,
                                                ( SELECT @Cel2Phon AS '@phonnumb' ,
                                                  ( SELECT '022' AS '@type' ,
                                                           @MsgbText
                                                       FOR XML PATH('Message') , TYPE )
                                                     FOR XML PATH('Contact') , TYPE ) ,
                                                ( SELECT @Cel3Phon AS '@phonnumb' ,
                                                  ( SELECT '022' AS '@type' ,
                                                           @MsgbText
                                                       FOR XML PATH('Message') , TYPE )
                                                     FOR XML PATH('Contact') , TYPE ) ,
                                                ( SELECT @Cel4Phon AS '@phonnumb' ,
                                                  ( SELECT '022' AS '@type' , 
                                                           @MsgbText
                                                       FOR XML PATH('Message') , TYPE )
                                                     FOR XML PATH('Contact') , TYPE ) ,
                                                ( SELECT @Cel5Phon AS '@phonnumb' ,
                                                  ( SELECT '022' AS '@type' ,
                                                           @MsgbText
                                                       FOR XML PATH('Message') , TYPE )
                                                     FOR XML PATH('Contact') , TYPE )
                                         FOR XML PATH('Contacts') , ROOT('Process') );
                    EXEC dbo.MSG_SEND_P @X = @XMsg; -- xml                  
                END;
           END;
         
       -- اگر برای هنرجو تعداد جلسه مشخص شده باشد
       IF EXISTS ( SELECT *
                     FROM dbo.Fighter f ,
                          dbo.Member_Ship m ,
                          Attendance A ,
                          INSERTED i ,
                          DELETED D
                    WHERE f.FILE_NO = m.FIGH_FILE_NO
                      AND f.MBSP_RWNO_DNRM = m.RWNO
                      AND m.RECT_CODE = '004'
                      AND A.FIGH_FILE_NO = m.FIGH_FILE_NO
                      AND A.MBSP_RWNO_DNRM = m.RWNO
                      AND A.MBSP_RECT_CODE_DNRM = m.RECT_CODE
                      AND A.FIGH_FILE_NO = i.FIGH_FILE_NO
                      AND i.FIGH_FILE_NO = D.FIGH_FILE_NO
                      AND i.CODE = D.CODE
                      AND i.ATTN_TYPE != '008' -- 1396/07/16 * اگر همراه بدون کسر جلسه باشد
                      AND i.ATTN_STAT = '001' -- الان ابطال شده
                      AND D.ATTN_STAT = '002' -- قبلا فعال بوده
                      AND ISNULL(m.NUMB_OF_ATTN_MONT, 0) >= 1 -- هنرجو جلسه ای باشد
                      AND a.ATTN_TYPE NOT IN ('006', '008', '009')
       )
       BEGIN
           UPDATE dbo.Member_Ship
               SET SUM_ATTN_MONT_DNRM = ISNULL(SUM_ATTN_MONT_DNRM, 0) - 1
             WHERE EXISTS ( SELECT *
                              FROM INSERTED I ,
                                   Attendance A ,
                                   DELETED D
                             WHERE dbo.Member_Ship.FIGH_FILE_NO = A.FIGH_FILE_NO
                               AND dbo.Member_Ship.RWNO = A.MBSP_RWNO_DNRM
                               AND dbo.Member_Ship.RECT_CODE = A.MBSP_RECT_CODE_DNRM
                               AND A.FIGH_FILE_NO = I.FIGH_FILE_NO
                               AND I.FIGH_FILE_NO = D.FIGH_FILE_NO
                               AND I.CODE = D.CODE
                               AND I.CODE = A.CODE
                               AND I.ATTN_STAT = '001' -- الان ابطال شده
                               AND D.ATTN_STAT = '002' -- قبلا فعال بوده
                               AND dbo.Member_Ship.RECT_CODE = '004'
                               AND dbo.Member_Ship.RWNO = A.MBSP_RWNO_DNRM 
                               -- 1403/12/03
                               AND a.ATTN_TYPE NOT IN ('006', '008', '009'));
             
           -- اگر گزینه ثبت نام مشارکتی در میان باشد آن دسته از افرادی که شماره پرسنلی یکسانی دارند باید یک جلسه از آنها هم کم شود
           IF EXISTS ( SELECT *
                          FROM dbo.Settings s ,
                               Inserted i ,
                               dbo.Club_Method cm ,
                               dbo.Method m
                         WHERE s.CLUB_CODE = cm.CLUB_CODE
                           AND cm.CODE = i.CBMT_CODE_DNRM
                           AND m.CODE = cm.MTOD_CODE
                           AND s.SHAR_MBSP_STAT = '002'
                           AND ISNULL(i.GLOB_CODE_DNRM, '') != ''
                           AND m.CHCK_ATTN_ALRM = '002' 
                           -- 1403/12/03
                           AND i.ATTN_TYPE NOT IN ('006', '008', '009'))
             BEGIN
                 UPDATE ms
                    SET ms.SUM_ATTN_MONT_DNRM = ISNULL(ms.SUM_ATTN_MONT_DNRM, 0) - 1
                   FROM dbo.Member_Ship ms ,
                        dbo.Fighter_Public fp ,
                        dbo.Attendance A ,
                        INSERTED I ,
                        dbo.Method m
                  WHERE I.CODE = A.CODE
                    AND ms.RECT_CODE = '004' -- رکورد نهایی شده						   
                    AND ms.FIGH_FILE_NO != A.FIGH_FILE_NO -- کاری به فرد جاری نداریم و دنبال مابقی افراد با کد مالی یکسان هستیم
                    AND ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
                    AND ms.FGPB_RWNO_DNRM = fp.RWNO
                    AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
                    AND fp.GLOB_CODE = A.GLOB_CODE_DNRM -- افرادی که داری کد پرسنلی یکسان هستند
                    AND fp.MTOD_CODE = A.MTOD_CODE_DNRM -- به دنبال ورزش مشارکتی
                    AND ms.VALD_TYPE = '002'
                    AND A.MTOD_CODE_DNRM = m.CODE
                    AND m.CHCK_ATTN_ALRM = '002' -- ورزش مشارکتی 
                    -- 1403/12/03
                    AND a.ATTN_TYPE NOT IN ('006', '008', '009')
                    AND ISNULL(ms.NUMB_OF_ATTN_MONT, 0) > 0
                    AND ISNULL(ms.NUMB_OF_ATTN_MONT, 0) >= ISNULL(ms.SUM_ATTN_MONT_DNRM, 0) /*- 1*/
                    AND CAST(A.ATTN_DATE AS DATE) BETWEEN CAST(STRT_DATE AS DATE) AND CAST(END_DATE AS DATE);
              END;
       END;
  END;
   
  -- چک کردن ثبت شماره کمد که برای دونفر که در باشگاه هستن ثبت نشود
  IF EXISTS ( SELECT *
                FROM dbo.Fighter f ,
                     Inserted I ,
                     dbo.Settings S
               WHERE f.FILE_NO = I.FIGH_FILE_NO
                 AND f.CLUB_CODE_DNRM = S.CLUB_CODE
                 AND S.MORE_FIGH_ONE_DRES = '001'
                 AND S.DRES_AUTO = '001'
                 AND ISNULL(I.DERS_NUMB, 0) <> 0
                 AND I.EXIT_TIME IS NULL
                 AND EXISTS ( SELECT *
                                FROM dbo.Attendance a
                               WHERE a.DERS_NUMB = I.DERS_NUMB
                                 AND a.CODE != I.CODE
                                 AND a.EXIT_TIME IS NULL ) )
  BEGIN
    DECLARE @AttnDate VARCHAR(10) ,
        @NameDnrm NVARCHAR(500) ,
        @CellPhonDnrm VARCHAR(11) ,
        @DersNumb INT;

    SELECT TOP 1
           @AttnDate = dbo.GET_MTOS_U(a.ATTN_DATE) ,
           @NameDnrm = f.NAME_DNRM ,
           @CellPhonDnrm = f.CELL_PHON_DNRM ,
           @DersNumb = i.DERS_NUMB
      FROM dbo.Fighter f ,
           dbo.Attendance a ,
           Inserted i
     WHERE f.FILE_NO = a.FIGH_FILE_NO
       AND f.FILE_NO != i.FIGH_FILE_NO
       AND a.DERS_NUMB = i.DERS_NUMB
       AND a.EXIT_TIME IS NULL
     ORDER BY a.ATTN_DATE;

    DECLARE @ErrMsg NVARCHAR(1000);
    SELECT  @ErrMsg = N' تداخل در ثبت شماره کمد '
            + CAST(@DersNumb AS NVARCHAR(10)) + N' ' + CHAR(10)
            + N' شماره کمد مورد نظر آخرین بار توسط ' + @NameDnrm
            + N' در تاریخ ' + @AttnDate
            + N' گرفته شده و پس داده نشده ' + CHAR(10)
            + CASE WHEN COALESCE(@CellPhonDnrm, '') = ''
                   THEN N' متاسفانه برای پیگیری شماره ای در سیستم ثبت نشده '
                   ELSE N' برای پیگیری می توانید با این شماره '
                        + @CellPhonDnrm + N' تماس حاصل کنید '
              END;

    RAISERROR(@ErrMsg, 16, 1);
  END;

  -- 1398/04/20 * آزاد کردن کمد انلاین
  IF EXISTS ( SELECT *
                FROM dbo.Settings s ,
                     Inserted i
               WHERE s.DRES_AUTO = '002'
                 AND ISNULL(i.DERS_NUMB, 0) <> 0
                 AND i.EXIT_TIME IS NOT NULL )
  BEGIN
    UPDATE da
       SET da.TKBK_TIME = GETDATE()
      FROM dbo.Dresser_Attendance da ,
           Inserted i
     WHERE da.ATTN_CODE = i.CODE
       AND i.EXIT_TIME IS NOT NULL;
  END;
END;
GO
ALTER TABLE [dbo].[Attendance] ADD CONSTRAINT [PK_ATTN] PRIMARY KEY CLUSTERED  ([CODE]) ON [BLOB]
GO
ALTER TABLE [dbo].[Attendance] ADD CONSTRAINT [FK_ATTN_CBMT] FOREIGN KEY ([CBMT_CODE_DNRM]) REFERENCES [dbo].[Club_Method] ([CODE])
GO
ALTER TABLE [dbo].[Attendance] ADD CONSTRAINT [FK_ATTN_CLUB] FOREIGN KEY ([CLUB_CODE]) REFERENCES [dbo].[Club] ([CODE])
GO
ALTER TABLE [dbo].[Attendance] ADD CONSTRAINT [FK_ATTN_COCH] FOREIGN KEY ([COCH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO])
GO
ALTER TABLE [dbo].[Attendance] ADD CONSTRAINT [FK_ATTN_CTGY] FOREIGN KEY ([CTGY_CODE_DNRM]) REFERENCES [dbo].[Category_Belt] ([CODE])
GO
ALTER TABLE [dbo].[Attendance] ADD CONSTRAINT [FK_ATTN_FIGH] FOREIGN KEY ([FIGH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Attendance] ADD CONSTRAINT [FK_ATTN_MBSP] FOREIGN KEY ([FIGH_FILE_NO], [MBSP_RECT_CODE_DNRM], [MBSP_RWNO_DNRM]) REFERENCES [dbo].[Member_Ship] ([FIGH_FILE_NO], [RECT_CODE], [RWNO])
GO
ALTER TABLE [dbo].[Attendance] ADD CONSTRAINT [FK_ATTN_MTOD] FOREIGN KEY ([MTOD_CODE_DNRM]) REFERENCES [dbo].[Method] ([CODE])
GO
ALTER TABLE [dbo].[Attendance] ADD CONSTRAINT [FK_ATTN_SESN] FOREIGN KEY ([SESN_SNID_DNRM]) REFERENCES [dbo].[Session] ([SNID])
GO
EXEC sp_addextendedproperty N'MS_Description', N'ATTN', 'SCHEMA', N'dbo', 'TABLE', N'Attendance', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'تاریخ حضور', 'SCHEMA', N'dbo', 'TABLE', N'Attendance', 'COLUMN', N'ATTN_DATE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت حضور و غیاب', 'SCHEMA', N'dbo', 'TABLE', N'Attendance', 'COLUMN', N'ATTN_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نحوه حضور و غیاب', 'SCHEMA', N'dbo', 'TABLE', N'Attendance', 'COLUMN', N'ATTN_SYS_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع حضوری', 'SCHEMA', N'dbo', 'TABLE', N'Attendance', 'COLUMN', N'ATTN_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد باشگاه', 'SCHEMA', N'dbo', 'TABLE', N'Attendance', 'COLUMN', N'CLUB_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد', 'SCHEMA', N'dbo', 'TABLE', N'Attendance', 'COLUMN', N'CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره کمد', 'SCHEMA', N'dbo', 'TABLE', N'Attendance', 'COLUMN', N'DERS_NUMB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'زمان ورود', 'SCHEMA', N'dbo', 'TABLE', N'Attendance', 'COLUMN', N'ENTR_TIME'
GO
EXEC sp_addextendedproperty N'MS_Description', N'زمان خروج', 'SCHEMA', N'dbo', 'TABLE', N'Attendance', 'COLUMN', N'EXIT_TIME'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره پرونده', 'SCHEMA', N'dbo', 'TABLE', N'Attendance', 'COLUMN', N'FIGH_FILE_NO'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد تمدید', 'SCHEMA', N'dbo', 'TABLE', N'Attendance', 'COLUMN', N'MBSP_RECT_CODE_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ردیف شماره تمدید', 'SCHEMA', N'dbo', 'TABLE', N'Attendance', 'COLUMN', N'MBSP_RWNO_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'سهم خدمات نیرو', 'SCHEMA', N'dbo', 'TABLE', N'Attendance', 'COLUMN', N'OWNR_CBMT_CODE_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت محاسبه هزینه مربی', 'SCHEMA', N'dbo', 'TABLE', N'Attendance', 'COLUMN', N'RCPT_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'میزان رضایتمندی مشتریان', 'SCHEMA', N'dbo', 'TABLE', N'Attendance', 'COLUMN', N'RTNG_NUMB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ارسال پیامک انجام شده', 'SCHEMA', N'dbo', 'TABLE', N'Attendance', 'COLUMN', N'SEND_MESG_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد جلسات', 'SCHEMA', N'dbo', 'TABLE', N'Attendance', 'COLUMN', N'TOTL_SESN'
GO
