CREATE TABLE [dbo].[Session_Meeting]
(
[MBSP_FIGH_FILE_NO] [bigint] NOT NULL,
[MBSP_RECT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[MBSP_RWNO] [smallint] NOT NULL,
[EXPN_CODE] [bigint] NOT NULL,
[SESN_SNID] [bigint] NOT NULL,
[RWNO] [smallint] NOT NULL,
[VALD_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ACTN_DATE] [date] NULL,
[STRT_TIME] [time] (0) NULL,
[END_TIME] [time] (0) NULL,
[MEET_MINT_DNRM] [int] NULL,
[NUMB_OF_GAYS] [smallint] NULL,
[EXPN_PRIC] [int] NULL,
[EXPN_EXTR_PRCT] [int] NULL,
[REMN_PRIC] [int] NULL,
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
CREATE TRIGGER [dbo].[CG$ADEL_SNMT]
   ON  [dbo].[Session_Meeting]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
/*   MERGE dbo.[Session_Meeting] T
   USING (SELECT * FROM INSERTED) S
   ON (T.MBSP_FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO AND
       T.MBSP_RECT_CODE    = S.MBSP_RECT_CODE    AND
       T.MBSP_RWNO         = S.MBSP_RWNO         AND
       T.SESN_SNID         = S.SESN_SNID         AND
       T.RWNO              = S.RWNO)
   WHEN MATCHED THEN
      UPDATE
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE()
            ,MEET_MINT_DNRM = CASE WHEN S.END_TIME IS NOT NULL THEN DATEDIFF(MINUTE, S.STRT_TIME, S.END_TIME) END;
*/
   -- برای محاسبه مجدد
   UPDATE dbo.[Session]
      SET SESN_TYPE = SESN_TYPE
    WHERE EXISTS(
      SELECT * 
        FROM DELETED S
       WHERE S.MBSP_FIGH_FILE_NO = MBSP_FIGH_FILE_NO
         AND S.MBSP_RECT_CODE = MBSP_RECT_CODE
         AND S.MBSP_RWNO = MBSP_RWNO
         AND S.SESN_SNID = SNID
    );
END;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AINS_SNMT]
   ON  [dbo].[Session_Meeting]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   IF EXISTS(
      SELECT *
        FROM Request r, Member_Ship m, Session_Meeting sm, Inserted i
       WHERE R.RQID = M.RQRO_RQST_RQID
         AND M.FIGH_FILE_NO = Sm.MBSP_FIGH_FILE_NO
         AND M.RECT_CODE = Sm.MBSP_RECT_CODE
         AND M.RWNO = Sm.MBSP_RWNO
         AND M.RECT_CODE = I.MBSP_RECT_CODE
         AND M.RECT_CODE = '001' -- زمانی که میخواهیم ثبت اطلاعات و اجاره را شروع کنیم
         AND R.RQTP_CODE = '016'
         AND R.RQTT_CODE = '007'
         AND R.RQST_STAT = '001'
         AND I.EXPN_CODE = Sm.EXPN_CODE
         AND Sm.VALD_TYPE = '002'
         
         AND Sm.END_TIME IS NULL
         
         AND NOT 
             ( I.MBSP_FIGH_FILE_NO = Sm.MBSP_FIGH_FILE_NO
           AND I.MBSP_RECT_CODE = Sm.MBSP_RECT_CODE
           AND I.MBSP_RWNO = Sm.MBSP_RWNO
           AND I.SESN_SNID = Sm.SESN_SNID         
         )       
   )
   BEGIN
      RAISERROR ( N'آیتم وارد شده در اختیار شخص دیگری می باشد. لطفا صبر کنید تا زمان اجاره آن تمام شود', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
   -- Insert statements for trigger here
   MERGE dbo.Session_Meeting T
   USING (SELECT * FROM INSERTED) S
   ON (T.MBSP_FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO AND
       T.MBSP_RECT_CODE    = S.MBSP_RECT_CODE    AND
       T.MBSP_RWNO         = S.MBSP_RWNO         AND
       --T.STRT_TIME         IS NULL               AND
       T.RWNO              = 0                   AND
       T.SESN_SNID         = S.SESN_SNID)
   WHEN MATCHED THEN
      UPDATE
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,ACTN_DATE = GETDATE()
            ,STRT_TIME = CASE WHEN S.STRT_TIME IS NULL THEN DATEADD(SECOND, (SELECT DATEPART(SECOND, TIME_WATE) +  60 * DATEPART(MINUTE, TIME_WATE) + 3600 * DATEPART(HOUR, TIME_WATE) FROM [Session] Sb WHERE Sb.SNID = S.SESN_SNID), GETDATE()) ELSE S.STRT_TIME END
            ,RWNO      = (
               SELECT ISNULL(MAX(RWNO),0) + 1 
                 FROM Session_Meeting Sm 
                WHERE Sm.MBSP_FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO
                  AND Sm.MBSP_RECT_CODE    = S.MBSP_RECT_CODE
                  AND Sm.MBSP_RWNO         = S.MBSP_RWNO
                  AND Sm.SESN_SNID         = S.SESN_SNID                  
            );

END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_SNMT]
   ON  [dbo].[Session_Meeting]
   AFTER UPDATE
AS 
BEGIN
   BEGIN TRY
   BEGIN TRAN T_CG$AUPD_SNMT
	   -- SET NOCOUNT ON added to prevent extra result sets from
	   -- interfering with SELECT statements.
	   SET NOCOUNT ON;
      
      IF EXISTS(
         SELECT *
           FROM Request r, Member_Ship m, Session_Meeting sm, Inserted i
          WHERE R.RQID = M.RQRO_RQST_RQID
            AND M.FIGH_FILE_NO = Sm.MBSP_FIGH_FILE_NO
            AND M.RECT_CODE = Sm.MBSP_RECT_CODE
            AND M.RWNO = Sm.MBSP_RWNO
            AND M.RECT_CODE = I.MBSP_RECT_CODE
            AND M.RECT_CODE = '001' -- زمانی که میخواهیم ثبت اطلاعات و اجاره را شروع کنیم
            AND R.RQTP_CODE = '016'
            AND R.RQTT_CODE = '007'
            AND R.RQST_STAT = '001'
            AND I.EXPN_CODE = Sm.EXPN_CODE
            AND Sm.VALD_TYPE = '002'
            
            AND Sm.END_TIME IS NULL
            
            AND NOT 
                ( I.MBSP_FIGH_FILE_NO = Sm.MBSP_FIGH_FILE_NO
              AND I.MBSP_RECT_CODE = Sm.MBSP_RECT_CODE
              AND I.MBSP_RWNO = Sm.MBSP_RWNO
              AND I.SESN_SNID = Sm.SESN_SNID         
            )       
      )
      BEGIN
         RAISERROR ( N'آیتم وارد شده در اختیار شخص دیگری می باشد. لطفا صبر کنید تا زمان اجاره آن تمام شود', -- Message text.
                  16, -- Severity.
                  1 -- State.
                  );
         RETURN;
      END
      -- Insert statements for trigger here
      MERGE dbo.[Session_Meeting] T
      USING (SELECT * FROM INSERTED) S
      ON (T.MBSP_FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO AND
          T.MBSP_RECT_CODE    = S.MBSP_RECT_CODE    AND
          T.MBSP_RWNO         = S.MBSP_RWNO         AND
          T.EXPN_CODE         = S.EXPN_CODE         AND
          T.SESN_SNID         = S.SESN_SNID         AND
          T.RWNO              = S.RWNO)
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
               ,MEET_MINT_DNRM = CASE WHEN S.VALD_TYPE = '002' AND S.END_TIME IS NOT NULL THEN DATEDIFF(MINUTE, S.STRT_TIME, S.END_TIME) ELSE NULL END;
      
      IF EXISTS(
         SELECT *
           FROM dbo.Session S, dbo.Session_Meeting sm, INSERTED i
          WHERE Sm.MBSP_FIGH_FILE_NO = i.MBSP_FIGH_FILE_NO
            AND Sm.MBSP_RWNO = i.MBSP_RWNO
            AND Sm.MBSP_RECT_CODE = i.MBSP_RECT_CODE
            AND Sm.EXPN_CODE = i.EXPN_CODE
            AND S.MBSP_FIGH_FILE_NO = i.MBSP_FIGH_FILE_NO
            AND S.MBSP_RWNO = i.MBSP_RWNO
            AND S.MBSP_RECT_CODE = i.MBSP_RECT_CODE            
            AND S.EXPN_CODE = i.EXPN_CODE
            AND S.SNID = Sm.SESN_SNID
            AND Sm.RWNO = i.RWNO
            AND S.MTOD_CODE_DNRM <> Sm.MTOD_CODE_DNRM
      )
      BEGIN
         RAISERROR( N'سبک هنرجوی وارد شده با سبک زمان ثبت نام متناقض می باشد لطفا برنامه کلاسی درست را انتخاب کنید', 16, 1 );
         RETURN;
      END
      
      -- برای محاسبه مجدد
      UPDATE dbo.[Session]
         SET SESN_TYPE = SESN_TYPE
       WHERE EXISTS(
         SELECT * 
           FROM INSERTED S
          WHERE S.MBSP_FIGH_FILE_NO = MBSP_FIGH_FILE_NO
            AND S.MBSP_RECT_CODE = MBSP_RECT_CODE
            AND S.MBSP_RWNO = MBSP_RWNO
            AND S.SESN_SNID = SNID
       );
   COMMIT TRAN T_CG$AUPD_SNMT
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T_CG$AUPD_SNMT;
   END CATCH
END;
GO
ALTER TABLE [dbo].[Session_Meeting] ADD CONSTRAINT [PK_SNMT] PRIMARY KEY CLUSTERED  ([SESN_SNID], [RWNO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Session_Meeting] WITH NOCHECK ADD CONSTRAINT [FK_SNMT_CBMT] FOREIGN KEY ([CBMT_CODE]) REFERENCES [dbo].[Club_Method] ([CODE])
GO
ALTER TABLE [dbo].[Session_Meeting] WITH NOCHECK ADD CONSTRAINT [FK_SNMT_CTGY] FOREIGN KEY ([CTGY_CODE_DNRM]) REFERENCES [dbo].[Category_Belt] ([CODE])
GO
ALTER TABLE [dbo].[Session_Meeting] WITH NOCHECK ADD CONSTRAINT [FK_SNMT_EXPN] FOREIGN KEY ([EXPN_CODE]) REFERENCES [dbo].[Expense] ([CODE])
GO
ALTER TABLE [dbo].[Session_Meeting] WITH NOCHECK ADD CONSTRAINT [FK_SNMT_FIGH] FOREIGN KEY ([COCH_FILE_NO_DNRM]) REFERENCES [dbo].[Fighter] ([FILE_NO])
GO
ALTER TABLE [dbo].[Session_Meeting] WITH NOCHECK ADD CONSTRAINT [FK_SNMT_MBSP] FOREIGN KEY ([MBSP_FIGH_FILE_NO], [MBSP_RECT_CODE], [MBSP_RWNO]) REFERENCES [dbo].[Member_Ship] ([FIGH_FILE_NO], [RECT_CODE], [RWNO])
GO
ALTER TABLE [dbo].[Session_Meeting] WITH NOCHECK ADD CONSTRAINT [FK_SNMT_MTOD] FOREIGN KEY ([MTOD_CODE_DNRM]) REFERENCES [dbo].[Method] ([CODE])
GO
ALTER TABLE [dbo].[Session_Meeting] ADD CONSTRAINT [FK_SNMT_SESN] FOREIGN KEY ([SESN_SNID]) REFERENCES [dbo].[Session] ([SNID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Session_Meeting] NOCHECK CONSTRAINT [FK_SNMT_CBMT]
GO
EXEC sp_addextendedproperty N'Short_Name', N'SNMT', 'SCHEMA', N'dbo', 'TABLE', N'Session_Meeting', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'انتهای زمان بازی', 'SCHEMA', N'dbo', 'TABLE', N'Session_Meeting', 'COLUMN', N'END_TIME'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کل دقایق بازی', 'SCHEMA', N'dbo', 'TABLE', N'Session_Meeting', 'COLUMN', N'MEET_MINT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد نفرات حاضر در جلسه', 'SCHEMA', N'dbo', 'TABLE', N'Session_Meeting', 'COLUMN', N'NUMB_OF_GAYS'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ردیف', 'SCHEMA', N'dbo', 'TABLE', N'Session_Meeting', 'COLUMN', N'RWNO'
GO
EXEC sp_addextendedproperty N'MS_Description', N'زمان شروع بازی', 'SCHEMA', N'dbo', 'TABLE', N'Session_Meeting', 'COLUMN', N'STRT_TIME'
GO
EXEC sp_addextendedproperty N'MS_Description', N'جلسه معتبر است', 'SCHEMA', N'dbo', 'TABLE', N'Session_Meeting', 'COLUMN', N'VALD_TYPE'
GO
