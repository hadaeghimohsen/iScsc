CREATE TABLE [dbo].[Attendance]
(
[CLUB_CODE] [bigint] NOT NULL,
[FIGH_FILE_NO] [bigint] NOT NULL,
[ATTN_DATE] [date] NOT NULL,
[CODE] [bigint] NOT NULL,
[MBSP_RWNO_DNRM] [smallint] NULL,
[MBSP_RECT_CODE_DNRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Attendance_MBSP_RECT_CODE_DNRM] DEFAULT ('004'),
[COCH_FILE_NO] [bigint] NULL,
[ATTN_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Attendance_ATTN_TYPE] DEFAULT ('001'),
[ENTR_TIME] [time] (0) NULL,
[EXIT_TIME] [time] (0) NULL,
[TOTL_SESN] [smallint] NULL CONSTRAINT [DF_Attendance_TOTL_SESN] DEFAULT ((1)),
[ATTN_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Attendance_ATTN_STAT] DEFAULT ('002'),
[DERS_NUMB] [int] NULL,
[NAME_DNRM] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CELL_PHON_DNRM] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FGPB_TYPE_DNRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
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
                    f.MBSP_RWNO_DNRM ,
                    f.NAME_DNRM ,
                    f.CELL_PHON_DNRM ,
                    f.FGPB_TYPE_DNRM ,
                    ISNULL(f.MTOD_CODE_DNRM, i.MTOD_CODE_DNRM) AS MTOD_CODE_DNRM ,
                    ISNULL(f.CTGY_CODE_DNRM, i.CTGY_CODE_DNRM) AS CTGY_CODE_DNRM ,
                    f.IMAG_RCDC_RCID_DNRM ,
                    f.IMAG_RWNO_DNRM ,
                    f.FNGR_PRNT_DNRM ,
                    f.DEBT_DNRM ,
                    f.BUFE_DEBT_DNTM ,
                    f.MBSP_STRT_DATE ,
                    f.MBSP_END_DATE ,
                    i.ATTN_TYPE
          FROM      INSERTED i ,
                    dbo.Fighter f
                    LEFT OUTER JOIN dbo.Member_Ship m ON m.FIGH_FILE_NO = f.FILE_NO
                                                         AND m.RWNO = f.MBSP_RWNO_DNRM
                                                         AND m.RECT_CODE = '004'
          WHERE     i.FIGH_FILE_NO = f.FILE_NO
        ) S
    ON ( T.CLUB_CODE = S.CLUB_CODE
         AND T.FIGH_FILE_NO = S.FIGH_FILE_NO
         AND CAST(T.ATTN_DATE AS DATE) = CAST(S.ATTN_DATE AS DATE)
         AND T.CODE = S.CODE
       )
    WHEN MATCHED THEN
        UPDATE SET
               T.CRET_BY = UPPER(SUSER_NAME()) ,
               T.CRET_DATE = GETDATE()
            --,CODE      = dbo.Gnrt_Nvid_U()
               ,
               T.ENTR_TIME = CAST(GETDATE() AS TIME(0)) ,
               T.MBSP_RECT_CODE_DNRM = CASE WHEN /*EXISTS (SELECT * FROM dbo.Fighter WHERE FILE_NO = S.Figh_File_No AND*/ S.FGPB_TYPE_DNRM NOT IN (
                                                 '002', '003' ) THEN '004'
                                            ELSE NULL
                                       END ,
               T.MBSP_RWNO_DNRM = /*(SELECT MBSP_RWNO_DNRM FROM dbo.Fighter WHERE FILE_NO = S.Figh_File_No)*/ S.MBSP_RWNO_DNRM ,
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
                                           THEN ISNULL(S.SUM_ATTN_MONT_DNRM, 0)
                                                + 1
                                           WHEN S.FGPB_TYPE_DNRM NOT IN (
                                                '002', '003' )
                                                AND S.ATTN_TYPE = '008'
                                           THEN ISNULL(S.SUM_ATTN_MONT_DNRM, 0)
                                           ELSE NULL
                                      END ,
               T.MBCO_RWNO_DNRM = S.MBCO_RWNO_DNRM ,
               T.ATTN_DESC = CASE WHEN S.ATTN_TYPE = '007'
                                  THEN N'ثبت جلسه حضوری با همراه با کسر جلسه از اعضا'
                                  WHEN S.ATTN_TYPE = '008'
                                  THEN N'ثبت جلسه حضوری با همراه بدون کسر جلسه از اعضا'
                                  ELSE NULL
                             END;
                                 
                                  
   
   -- اختصاص کلید کمد به کاربر اگر سامانه کمد فعال باشد و به صورت اتوماتیک انجام شود
    IF EXISTS ( SELECT  *
                FROM    Attendance A ,
                        Inserted I
                WHERE   A.CODE = I.CODE
                        AND A.EXIT_TIME IS NULL )
        AND EXISTS ( SELECT *
                     FROM   Settings
                     WHERE  DRES_STAT = '002'
                            AND DRES_AUTO = '002' )
        BEGIN
            DECLARE @AttnCode BIGINT ,
                @DresCode BIGINT ,
                @ClubCode BIGINT;
            SELECT  @AttnCode = CODE ,
                    @ClubCode = CLUB_CODE
            FROM    Inserted;
            SELECT TOP 1
                    @DresCode = CODE
            FROM    Dresser D
            WHERE   D.REC_STAT = '002'
                    AND CLUB_CODE = @ClubCode
                    AND NOT EXISTS ( SELECT *
                                     FROM   Dresser_Attendance Da
                                     WHERE  Da.DRES_CODE = D.CODE
                                            AND Da.LEND_TIME IS NOT NULL
                                            AND Da.TKBK_TIME IS NULL );
            IF @DresCode IS NOT NULL
                INSERT  INTO Dresser_Attendance
                        ( DRES_CODE ,
                          ATTN_CODE ,
                          CODE ,
                          LEND_TIME
                        )
                VALUES  ( @DresCode ,
                          @AttnCode ,
                          dbo.GNRT_NVID_U() ,
                          CAST(GETDATE() AS TIME(0))
                        );
        END;
   

   -- ثبت جلسه برای هنرجویان عادی
   -- در جدول عضویت مشترکین
    IF EXISTS ( SELECT  *
                FROM    Fighter F ,
                        Inserted I
                WHERE   F.FILE_NO = I.FIGH_FILE_NO
                        AND F.FGPB_TYPE_DNRM IN ( '001', '005', '006' )
                        AND F.CONF_STAT = '002'
                        AND I.ATTN_TYPE != '008' /* همراهانی که بدون کسر جلسه وارد میشوند نیازی به تغییر تعداد جلسات نیست */)
        BEGIN
      -- اگر برای هنرجو تعداد جلسه مشخص شده باشد
            IF EXISTS ( SELECT  *
                        FROM    dbo.Fighter f ,
                                dbo.Member_Ship m ,
                                Attendance A ,
                                INSERTED i
                        WHERE   f.FILE_NO = m.FIGH_FILE_NO
                                AND f.MBSP_RWNO_DNRM = m.RWNO
                                AND m.RECT_CODE = '004'
                                AND A.FIGH_FILE_NO = m.FIGH_FILE_NO
                                AND A.MBSP_RWNO_DNRM = m.RWNO
                                AND A.MBSP_RECT_CODE_DNRM = m.RECT_CODE
                                AND A.FIGH_FILE_NO = i.FIGH_FILE_NO
                                AND ( ( ISNULL(m.NUMB_OF_ATTN_MONT, 0) >= 1
                                        AND ISNULL(m.NUMB_OF_ATTN_MONT, 0) > ISNULL(m.SUM_ATTN_MONT_DNRM,
                                                              0)
                                      )
                                      OR ( ISNULL(m.NUMB_OF_ATTN_MONT, 0) = 0 )
                                    ) )
                BEGIN         
                    UPDATE  dbo.Member_Ship
                    SET     SUM_ATTN_MONT_DNRM = ISNULL(SUM_ATTN_MONT_DNRM, 0)
                            + 1 ,
                            SUM_ATTN_WEEK_DNRM = dbo.GET_SATN_F('<Fighter fileno="'
                                                              + CAST(FIGH_FILE_NO AS VARCHAR(14))
                                                              + '"/>').query('//Attendance').value('(Attendance/@d)[1]',
                                                              'BIGINT')
                    WHERE   EXISTS ( SELECT *
                                     FROM   INSERTED I ,
                                            Attendance A
                                     WHERE  dbo.Member_Ship.FIGH_FILE_NO = A.FIGH_FILE_NO
                                            AND dbo.Member_Ship.RWNO = A.MBSP_RWNO_DNRM
                                            AND dbo.Member_Ship.RECT_CODE = A.MBSP_RECT_CODE_DNRM
                                            AND A.FIGH_FILE_NO = I.FIGH_FILE_NO
                                            AND dbo.Member_Ship.RECT_CODE = '004'
                                            AND CAST(A.ATTN_DATE AS DATE) = CAST(/*GETDATE()*/ I.ATTN_DATE AS DATE)
                                            AND A.ENTR_TIME IS NOT NULL
                                            AND ( ( A.ATTN_TYPE <> '002'
                                                    AND A.EXIT_TIME IS NULL
                                                  )
                                                  OR ( A.ATTN_TYPE = '002'
                                                       AND A.EXIT_TIME IS NOT NULL
                                                     )
                                                ) );
                END;
            ELSE
                BEGIN
                    RAISERROR(N'تعداد جلسات شما به پایان رسیده لطفا برای شارژ مجدد اقدام نمایید', 16, 1);
                    RETURN;
                END;
        END;
 
 
   -- ثبت جلسه برای هنرجویان جلسه ای
    IF EXISTS ( SELECT  *
                FROM    Fighter F ,
                        Inserted I
                WHERE   F.FILE_NO = I.FIGH_FILE_NO
                        AND F.FGPB_TYPE_DNRM IN ( '008', '009' )
                        AND F.CONF_STAT = '002' )
        BEGIN
      -- ثبت جلسه حضور برای هنرجویان تک روز چند جلسه ای
            IF EXISTS ( SELECT  *
                        FROM    Fighter F ,
                                Member_Ship M ,
                                inserted I
                        WHERE   F.FILE_NO = M.FIGH_FILE_NO
                                AND M.FIGH_FILE_NO = I.FIGH_FILE_NO
                                AND F.MBSP_RWNO_DNRM = M.RWNO
                                AND M.RECT_CODE = '004'
                                AND DATEDIFF(DAY, M.STRT_DATE, M.END_DATE) = 0 )
                BEGIN
                    IF EXISTS ( SELECT  *
                                FROM    Fighter F ,
                                        Member_Ship M ,
                                        [Session] S ,
                                        inserted I
                                WHERE   F.FILE_NO = M.FIGH_FILE_NO
                                        AND M.FIGH_FILE_NO = I.FIGH_FILE_NO
                                        AND F.MBSP_RWNO_DNRM = M.RWNO
                                        AND M.FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO
                                        AND M.RECT_CODE = S.MBSP_RECT_CODE
                                        AND M.RWNO = S.MBSP_RWNO
                                        AND M.RECT_CODE = '004'
                                        AND DATEDIFF(DAY, M.STRT_DATE,
                                                     M.END_DATE) = 0
                                        AND S.TOTL_SESN > ISNULL(S.SUM_MEET_HELD_DNRM,
                                                              0) )
                        BEGIN
                            MERGE Session_Meeting T
                            USING
                                ( SELECT    S.MBSP_FIGH_FILE_NO ,
                                            S.MBSP_RECT_CODE ,
                                            S.MBSP_RWNO ,
                                            S.EXPN_CODE ,
                                            S.SNID ,
                                            0 AS RWNO ,
                                            '002' AS VALD_TYPE ,
                                            GETDATE() AS STRT_TIME ,
                                            DATEADD(MINUTE, 90, GETDATE()) AS END_TIME ,
                                            1 AS NUMB_OF_GAYS
                                  FROM      Fighter F ,
                                            Member_Ship M ,
                                            [Session] S ,
                                            Inserted I
                                  WHERE     F.FILE_NO = I.FIGH_FILE_NO
                                            AND F.FILE_NO = M.FIGH_FILE_NO
                                            AND F.MBSP_RWNO_DNRM = M.RWNO
                                            AND M.RECT_CODE = '004'
                                            AND M.FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO
                                            AND M.RECT_CODE = S.MBSP_RECT_CODE
                                            AND M.RWNO = S.MBSP_RWNO
                                ) S
                            ON ( T.MBSP_FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO
                                 AND T.MBSP_RECT_CODE = S.MBSP_RECT_CODE
                                 AND T.MBSP_RWNO = S.MBSP_RWNO
                                 AND T.EXPN_CODE = S.EXPN_CODE
                                 AND T.SESN_SNID = S.SNID
                               )
                            WHEN NOT MATCHED THEN
                                INSERT ( MBSP_FIGH_FILE_NO ,
                                         MBSP_RECT_CODE ,
                                         MBSP_RWNO ,
                                         EXPN_CODE ,
                                         SESN_SNID ,
                                         RWNO ,
                                         VALD_TYPE ,
                                         STRT_TIME ,
                                         END_TIME ,
                                         NUMB_OF_GAYS
                                       )
                                VALUES ( S.MBSP_FIGH_FILE_NO ,
                                         S.MBSP_RECT_CODE ,
                                         S.MBSP_RWNO ,
                                         S.EXPN_CODE ,
                                         S.SNID ,
                                         0 ,
                                         '002' ,
                                         GETDATE() ,
                                         DATEADD(MINUTE, 90, GETDATE()) ,
                                         1
                                       )
                            WHEN MATCHED THEN
                                UPDATE SET
                                        NUMB_OF_GAYS = S.NUMB_OF_GAYS + 1;
                
            
            --INSERT INTO Session_Meeting (MBSP_FIGH_FILE_NO, MBSP_RECT_CODE, MBSP_RWNO, EXPN_CODE, SESN_SNID, RWNO, VALD_TYPE, STRT_TIME, END_TIME, NUMB_OF_GAYS)
            --SELECT M.FIGH_FILE_NO, M.RECT_CODE, M.RWNO, S.EXPN_CODE, S.SNID, 0, '002', GETDATE(), DATEADD(MINUTE, 90, GETDATE()), 1
            --  FROM Fighter F, Member_Ship M, [Session] S, Inserted I
            -- WHERE F.FILE_NO = I.FIGH_FILE_NO
            --   AND F.FILE_NO = M.FIGH_FILE_NO
            --   AND F.MBSP_RWNO_DNRM = M.RWNO
            --   AND M.RECT_CODE = '004'
            --   AND M.FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO
            --   AND M.RECT_CODE = S.MBSP_RECT_CODE
            --   AND M.RWNO = S.MBSP_RWNO;
            
            -- اختصاص کلید کمد به کاربر اگر سامانه کمد فعال باشد و به صورت اتوماتیک انجام شود
                            IF EXISTS ( SELECT  *
                                        FROM    Settings
                                        WHERE   DRES_STAT = '002'
                                                AND DRES_AUTO = '002' )
                                BEGIN      
               -- آزاد شدن کمد برای هنرجو باید به صورت دستی انجام شود         
                                    SELECT  @AttnCode = CODE ,
                                            @ClubCode = CLUB_CODE
                                    FROM    Inserted;
                                    SELECT TOP 1
                                            @DresCode = CODE
                                    FROM    Dresser D
                                    WHERE   D.REC_STAT = '002'
                                            AND CLUB_CODE = @ClubCode
                                            AND NOT EXISTS ( SELECT
                                                              *
                                                             FROM
                                                              Dresser_Attendance Da
                                                             WHERE
                                                              Da.DRES_CODE = D.CODE
                                                              AND Da.LEND_TIME IS NOT NULL
                                                              AND Da.TKBK_TIME IS NULL );
                                    IF @DresCode IS NOT NULL
                                        INSERT  INTO Dresser_Attendance
                                                ( DRES_CODE ,
                                                  ATTN_CODE ,
                                                  CODE ,
                                                  LEND_TIME
                                                )
                                        VALUES  ( @DresCode ,
                                                  @AttnCode ,
                                                  dbo.GNRT_NVID_U() ,
                                                  CAST(GETDATE() AS TIME(0))
                                                );
                                END;
                        END;
                    ELSE
                        BEGIN
                            RAISERROR(N'تعداد جلسات شما به پایان رسیده لطفا برای شارژ مجدد اقدام نمایید', 16, 1);
                            RETURN;
                        END;
         
                END;
            ELSE -- ثبت جلسه حضور برای هنرجویان چندجلسه ای
                IF EXISTS ( SELECT  *
                            FROM    Fighter F ,
                                    Member_Ship M ,
                                    inserted I
                            WHERE   F.FILE_NO = M.FIGH_FILE_NO
                                    AND M.FIGH_FILE_NO = I.FIGH_FILE_NO
                                    AND F.MBSP_RWNO_DNRM = M.RWNO
                                    AND M.RECT_CODE = '004'
                                    AND DATEDIFF(DAY, M.STRT_DATE, M.END_DATE) >= 1 )
                    BEGIN
                        IF EXISTS ( SELECT  *
                                    FROM    Fighter F ,
                                            Member_Ship M ,
                                            [Session] S ,
                                            Inserted I
                                    WHERE   F.FILE_NO = M.FIGH_FILE_NO
                                            AND M.FIGH_FILE_NO = I.FIGH_FILE_NO
                                            AND F.MBSP_RWNO_DNRM = M.RWNO
                                            AND M.FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO
                                            AND M.RECT_CODE = S.MBSP_RECT_CODE
                                            AND M.RWNO = S.MBSP_RWNO
                                            AND M.RECT_CODE = '004'
                                            AND DATEDIFF(DAY, M.STRT_DATE,
                                                         M.END_DATE) >= 1
                                            AND ( S.TOTL_SESN + 2 ) > ISNULL(S.SUM_MEET_HELD_DNRM,
                                                              0) )
                            BEGIN
                                IF ( EXISTS ( SELECT    *
                                              FROM      Settings S ,
                                                        Fighter F ,
                                                        inserted I
                                              WHERE     S.CLUB_CODE = F.CLUB_CODE_DNRM
                                                        AND F.FILE_NO = I.FIGH_FILE_NO
                                                        AND S.MORE_ATTN_SESN = '001' -- تک جلسه در روز
               )
                                     AND NOT EXISTS ( SELECT  *
                                                      FROM    Fighter F ,
                                                              Member_Ship M ,
                                                              [Session] S ,
                                                              Session_Meeting Sm ,
                                                              Inserted I
                                                      WHERE   F.FILE_NO = I.FIGH_FILE_NO
                                                              AND F.FILE_NO = M.FIGH_FILE_NO
                                                              AND F.MBSP_RWNO_DNRM = M.RWNO
                                                              AND M.RECT_CODE = '004'
                                                              AND M.FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO
                                                              AND M.RECT_CODE = S.MBSP_RECT_CODE
                                                              AND M.RWNO = S.MBSP_RWNO
                                                              AND S.SNID = Sm.SESN_SNID
                                                              AND S.MBSP_FIGH_FILE_NO = Sm.MBSP_FIGH_FILE_NO
                                                              AND S.MBSP_RECT_CODE = Sm.MBSP_RECT_CODE
                                                              AND S.MBSP_RWNO = Sm.MBSP_RWNO
                                                              AND CAST(Sm.ACTN_DATE AS DATE) = CAST(GETDATE() AS DATE) )
                                   )
                                    OR EXISTS ( SELECT  *
                                                FROM    Settings S ,
                                                        Fighter F ,
                                                        inserted I
                                                WHERE   S.CLUB_CODE = F.CLUB_CODE_DNRM
                                                        AND F.FILE_NO = I.FIGH_FILE_NO
                                                        AND S.MORE_ATTN_SESN = '002' -- چند جلسه در روز
            )
                                    BEGIN
               /*INSERT INTO Session_Meeting (MBSP_FIGH_FILE_NO, MBSP_RECT_CODE, MBSP_RWNO, EXPN_CODE, SESN_SNID, RWNO, VALD_TYPE, STRT_TIME, END_TIME, NUMB_OF_GAYS)
               SELECT M.FIGH_FILE_NO, M.RECT_CODE, M.RWNO, S.EXPN_CODE, S.SNID, 0, '002', GETDATE(), DATEADD(MINUTE, 90, GETDATE()), 1
                 FROM Fighter F, Member_Ship M, [Session] S, Inserted I
                WHERE F.FILE_NO = I.FIGH_FILE_NO
                  AND F.FILE_NO = M.FIGH_FILE_NO
                  AND F.MBSP_RWNO_DNRM = M.RWNO
                  AND M.RECT_CODE = '004'
                  AND M.FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO
                  AND M.RECT_CODE = S.MBSP_RECT_CODE
                  AND M.RWNO = S.MBSP_RWNO;  */
                                        UPDATE  dbo.Member_Ship
                                        SET     SUM_ATTN_MONT_DNRM = ISNULL(SUM_ATTN_MONT_DNRM,
                                                              0) + 1
                                        WHERE   EXISTS ( SELECT
                                                              *
                                                         FROM INSERTED I ,
                                                              Attendance A
                                                         WHERE
                                                              dbo.Member_Ship.FIGH_FILE_NO = A.FIGH_FILE_NO
                                                              AND dbo.Member_Ship.RWNO = A.MBSP_RWNO_DNRM
                                                              AND dbo.Member_Ship.RECT_CODE = A.MBSP_RECT_CODE_DNRM
                                                              AND A.FIGH_FILE_NO = I.FIGH_FILE_NO
                                                              AND dbo.Member_Ship.RECT_CODE = '004'
                                                              AND CAST(A.ATTN_DATE AS DATE) = CAST(/*GETDATE()*/ I.ATTN_DATE AS DATE)
                                                              AND A.ENTR_TIME IS NOT NULL
                                                              AND ( ( A.ATTN_TYPE <> '002'
                                                              AND A.EXIT_TIME IS NULL
                                                              )
                                                              OR ( A.ATTN_TYPE = '002'
                                                              AND A.EXIT_TIME IS NOT NULL
                                                              )
                                                              ) );                            
                                    END;
                                ELSE
                                    BEGIN
                                        RAISERROR(N'شما هنرجوی عزیز در طول روز فقط یک جلسه با مربی قادر به تمرین می باشید', 16, 1);
                                        RETURN;
                                    END;
                            END;
                        ELSE
                            BEGIN
                                RAISERROR(N'تعداد جلسات شما به پایان رسیده لطفا برای شارژ مجدد اقدام نمایید', 16, 1);
                                RETURN;
                            END;         
                    END;
        END;
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
    USING
        ( SELECT    *
          FROM      INSERTED
        ) S
    ON ( T.CLUB_CODE = S.CLUB_CODE
         AND T.FIGH_FILE_NO = S.FIGH_FILE_NO
         AND CAST(T.ATTN_DATE AS DATE) = CAST(S.ATTN_DATE AS DATE)
         AND T.CODE = S.CODE
       )
    WHEN MATCHED THEN
        UPDATE SET
               MDFY_BY = UPPER(SUSER_NAME()) ,
               MDFY_DATE = GETDATE();
            
            --,EXIT_TIME  = CASE WHEN DATEDIFF(MINUTE, CAST(GETDATE() AS TIME(0)), DATEADD(MINUTE, 1, S.ENTR_TIME)) <= 0 THEN CAST(GETDATE() AS TIME(0)) ELSE NULL END;
   
   -- پس گرفتن کلید کمد از کاربر اگر سامانه کمد فعال باشد و به صورت اتوماتیک انجام شود
/*   IF EXISTS(SELECT * FROM Attendance A, Inserted I WHERE A.CODE = I.CODE AND A.EXIT_TIME IS NOT NULL) AND
      EXISTS(SELECT * FROM Settings WHERE DRES_STAT = '002' AND DRES_AUTO = '002')
   BEGIN
      DECLARE @AttnCode BIGINT
             ,@DresCode BIGINT
             ,@ClubCode BIGINT;
      SELECT @AttnCode = Code, @ClubCode = Club_Code FROM Inserted;
      SELECT TOP 1 
             @DresCode = CODE
        FROM Dresser D 
       WHERE D.Rec_Stat = '002'       
         AND CLUB_CODE = @ClubCode
         AND EXISTS(
            SELECT * 
              FROM Dresser_Attendance Da
             WHERE Da.DRES_CODE = D.CODE
               AND Da.ATTN_CODE = @AttnCode
               AND Da.Lend_Time IS NOT NULL
               AND Da.Tkbk_Time IS NULL
         );
      IF @DresCode IS NOT NULL
         UPDATE Dresser_Attendance
            SET TKBK_TIME = CAST(GETDATE() AS TIME(0))
          WHERE DRES_CODE = @DresCode
            AND ATTN_CODE = @AttnCode
            AND LEND_TIME IS NOT NULL
            AND TKBK_TIME IS NULL;        
   END*/
   
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
      -- اگر برای هنرجو تعداد جلسه مشخص شده باشد
            IF EXISTS ( SELECT  *
                        FROM    dbo.Fighter f ,
                                dbo.Member_Ship m ,
                                Attendance A ,
                                INSERTED i ,
                                DELETED D
                        WHERE   f.FILE_NO = m.FIGH_FILE_NO
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
      )
                BEGIN         
                    UPDATE  dbo.Member_Ship
                    SET     SUM_ATTN_MONT_DNRM = ISNULL(SUM_ATTN_MONT_DNRM, 0)
                            - 1
               --,SUM_ATTN_WEEK_DNRM = dbo.GET_SATN_F('<Fighter fileno="' + CAST(Figh_File_No AS VARCHAR(14)) + '"/>').query('//Attendance').value('(Attendance/@d)[1]', 'BIGINT')
                    WHERE   EXISTS ( SELECT *
                                     FROM   INSERTED I ,
                                            Attendance A ,
                                            DELETED D
                                     WHERE  dbo.Member_Ship.FIGH_FILE_NO = A.FIGH_FILE_NO
                                            AND dbo.Member_Ship.RWNO = A.MBSP_RWNO_DNRM
                                            AND dbo.Member_Ship.RECT_CODE = A.MBSP_RECT_CODE_DNRM
                                            AND A.FIGH_FILE_NO = I.FIGH_FILE_NO
                                            AND I.FIGH_FILE_NO = D.FIGH_FILE_NO
                                            AND I.CODE = D.CODE
                                            AND I.ATTN_STAT = '001' -- الان ابطال شده
                                            AND D.ATTN_STAT = '002' -- قبلا فعال بوده
                                            AND dbo.Member_Ship.RECT_CODE = '004' );
                END;
        END;
   
   --SELECT * FROM Inserted
   -- چک کردن ثبت شماره کمد که برای دونفر که در باشگاه هستن ثبت نشود
    IF EXISTS ( SELECT  *
                FROM    dbo.Fighter f ,
                        Inserted I ,
                        dbo.Settings S
                WHERE   f.FILE_NO = I.FIGH_FILE_NO
                        AND f.CLUB_CODE_DNRM = S.CLUB_CODE
                        AND S.MORE_FIGH_ONE_DRES = '001'
                        AND ISNULL(I.DERS_NUMB, 0) <> 0
                        AND I.EXIT_TIME IS NULL
                        AND EXISTS ( SELECT *
                                     FROM   dbo.Attendance a
                                     WHERE  a.DERS_NUMB = I.DERS_NUMB
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
            FROM    dbo.Fighter f ,
                    dbo.Attendance a ,
                    Inserted i
            WHERE   f.FILE_NO = a.FIGH_FILE_NO
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
END;
GO
ALTER TABLE [dbo].[Attendance] ADD CONSTRAINT [PK_ATTN] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
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
EXEC sp_addextendedproperty N'MS_Description', N'تعداد جلسات', 'SCHEMA', N'dbo', 'TABLE', N'Attendance', 'COLUMN', N'TOTL_SESN'
GO
