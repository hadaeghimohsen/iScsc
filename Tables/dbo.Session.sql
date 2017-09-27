CREATE TABLE [dbo].[Session]
(
[MBSP_FIGH_FILE_NO] [bigint] NOT NULL,
[MBSP_RECT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[MBSP_RWNO] [smallint] NOT NULL,
[EXPN_CODE] [bigint] NULL,
[SESN_SNID] [bigint] NULL,
[SNID] [bigint] NOT NULL,
[SESN_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TIME_WATE] [time] (0) NULL CONSTRAINT [DF_Session_TIME_WATE] DEFAULT ('00:00:00'),
[TOTL_SESN] [smallint] NULL,
[SUM_MEET_HELD_DNRM] [smallint] NULL,
[SUM_MEET_MINT_DNRM] [int] NULL,
[CARD_NUMB] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CBMT_CODE] [bigint] NULL,
[MTOD_CODE_DNRM] [bigint] NULL,
[CTGY_CODE_DNRM] [bigint] NULL,
[COCH_FILE_NO_DNRM] [bigint] NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AINS_SESN]
   ON  [dbo].[Session]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   -- Insert statements for trigger here
   MERGE dbo.Session T
   USING (SELECT * FROM INSERTED) S
   ON (T.MBSP_FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO AND
       T.MBSP_RECT_CODE    = S.MBSP_RECT_CODE    AND
       T.MBSP_RWNO         = S.MBSP_RWNO         AND
       T.SNID              = S.SNID)
   WHEN MATCHED THEN
      UPDATE
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE();
            --,SNID      = dbo.GNRT_NVID_U();
   
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_SESN]
   ON  [dbo].[Session]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.[Session] T
   USING (SELECT * FROM INSERTED) S
   ON (T.MBSP_FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO AND
       T.MBSP_RECT_CODE    = S.MBSP_RECT_CODE    AND
       T.MBSP_RWNO         = S.MBSP_RWNO         AND
       T.SNID              = S.SNID)
   WHEN MATCHED THEN
      UPDATE
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE()
            ,COCH_FILE_NO_DNRM = CASE WHEN S.CBMT_CODE IS NULL THEN NULL
                                      ELSE (
                                       SELECT COCH_FILE_NO
                                         FROM dbo.Club_Method
                                        WHERE Code = S.CBMT_CODE
                                      )
                                 END
            ,MTOD_CODE_DNRM = CASE WHEN S.CBMT_CODE IS NULL THEN NULL
                                   ELSE (
                                    SELECT MTOD_CODE
                                      FROM dbo.Club_Method
                                     WHERE Code = S.CBMT_CODE
                                   )
                              END
            ,CTGY_CODE_DNRM = CASE WHEN S.CBMT_CODE IS NULL OR S.EXPN_CODE IS NULL THEN NULL
                                   ELSE (
                                    SELECT CTGY_CODE
                                      FROM dbo.Expense
                                     WHERE Code = S.EXPN_CODE
                                   )
                              END
            ,SUM_MEET_HELD_DNRM = 
               CASE S.SESN_TYPE 
                  WHEN '001' THEN NULL 
                  WHEN '002' THEN (
                     SELECT SUM(NUMB_OF_GAYS) 
                       FROM Session_Meeting Sm
                      WHERE Sm.MBSP_FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO
                        AND Sm.MBSP_RECT_CODE    = S.MBSP_RECT_CODE
                        AND Sm.MBSP_RWNO         = S.MBSP_RWNO
                        AND Sm.SESN_SNID         = S.SNID
                        AND Sm.VALD_TYPE         = '002'
                  ) 
                  WHEN '003' THEN (
                     SELECT SUM(NUMB_OF_GAYS) 
                       FROM Session_Meeting Sm
                      WHERE Sm.MBSP_FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO
                        AND Sm.MBSP_RECT_CODE    = S.MBSP_RECT_CODE
                        AND Sm.MBSP_RWNO         = S.MBSP_RWNO
                        AND Sm.SESN_SNID         = S.SNID
                        AND Sm.VALD_TYPE         = '002'
                  ) 
               END            
            ,SUM_MEET_MINT_DNRM = 
               CASE S.SESN_TYPE 
                  WHEN '002' THEN NULL 
                  WHEN '003' THEN NULL 
                  WHEN '001' THEN (
                     SELECT SUM(MEET_MINT_DNRM) 
                       FROM Session_Meeting Sm
                      WHERE Sm.MBSP_FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO
                        AND Sm.MBSP_RECT_CODE    = S.MBSP_RECT_CODE
                        AND Sm.MBSP_RWNO         = S.MBSP_RWNO
                        AND Sm.SESN_SNID         = S.SNID
                        AND Sm.VALD_TYPE         = '002'
                        AND Sm.STRT_TIME IS NOT NULL
                        AND Sm.END_TIME  IS NOT NULL
                  ) 
               END;
   
   MERGE dbo.Fighter T
   USING (SELECT S.MBSP_FIGH_FILE_NO, S.MBSP_RECT_CODE, S.CARD_NUMB, S.TOTL_SESN, S.SUM_MEET_HELD_DNRM 
            FROM INSERTED I, [Session] S, Member_Ship M
           WHERE  I.SESN_TYPE = '002'
             AND I.MBSP_RECT_CODE = '004'
             AND I.MBSP_FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO
             AND I.MBSP_RECT_CODE = S.MBSP_RECT_CODE
             AND I.MBSP_RWNO = S.MBSP_RWNO
             AND I.SNID = S.SNID
             AND I.SESN_TYPE = S.SESN_TYPE
             AND S.MBSP_FIGH_FILE_NO = M.FIGH_FILE_NO
             AND S.MBSP_RECT_CODE = M.RECT_CODE 
             AND S.MBSP_RWNO = M.RWNO
             AND DATEDIFF(DAY, M.STRT_DATE, M.END_DATE) = 0) S
   ON (T.FILE_NO   = S.MBSP_FIGH_FILE_NO AND
       S.MBSP_RECT_CODE = '004')
   WHEN MATCHED THEN
      UPDATE 
         SET CARD_NUMB_DNRM = CASE WHEN S.TOTL_SESN - ISNULL(S.SUM_MEET_HELD_DNRM, 0) > 0 THEN S.CARD_NUMB ELSE NULL END;

END
;
GO
ALTER TABLE [dbo].[Session] ADD CONSTRAINT [PK_SESN] PRIMARY KEY CLUSTERED  ([SNID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Session] WITH NOCHECK ADD CONSTRAINT [FK_SESN_CBMT] FOREIGN KEY ([CBMT_CODE]) REFERENCES [dbo].[Club_Method] ([CODE])
GO
ALTER TABLE [dbo].[Session] WITH NOCHECK ADD CONSTRAINT [FK_SESN_CTGY] FOREIGN KEY ([CTGY_CODE_DNRM]) REFERENCES [dbo].[Category_Belt] ([CODE])
GO
ALTER TABLE [dbo].[Session] WITH NOCHECK ADD CONSTRAINT [FK_SESN_EXPN] FOREIGN KEY ([EXPN_CODE]) REFERENCES [dbo].[Expense] ([CODE])
GO
ALTER TABLE [dbo].[Session] WITH NOCHECK ADD CONSTRAINT [FK_SESN_FIGH] FOREIGN KEY ([COCH_FILE_NO_DNRM]) REFERENCES [dbo].[Fighter] ([FILE_NO])
GO
ALTER TABLE [dbo].[Session] WITH NOCHECK ADD CONSTRAINT [FK_SESN_MBSP] FOREIGN KEY ([MBSP_FIGH_FILE_NO], [MBSP_RECT_CODE], [MBSP_RWNO]) REFERENCES [dbo].[Member_Ship] ([FIGH_FILE_NO], [RECT_CODE], [RWNO]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Session] WITH NOCHECK ADD CONSTRAINT [FK_SESN_MTOD] FOREIGN KEY ([MTOD_CODE_DNRM]) REFERENCES [dbo].[Method] ([CODE])
GO
ALTER TABLE [dbo].[Session] NOCHECK CONSTRAINT [FK_SESN_CBMT]
GO
EXEC sp_addextendedproperty N'Short_Name', N'SESN', 'SCHEMA', N'dbo', 'TABLE', N'Session', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره کارت برای مشتریان جلسه ای', 'SCHEMA', N'dbo', 'TABLE', N'Session', 'COLUMN', N'CARD_NUMB'
GO
