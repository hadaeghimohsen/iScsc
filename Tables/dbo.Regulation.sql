CREATE TABLE [dbo].[Regulation]
(
[YEAR] [smallint] NOT NULL,
[CODE] [int] NOT NULL CONSTRAINT [DF_REGL_CODE] DEFAULT ((0)),
[SUB_SYS] [smallint] NOT NULL,
[TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_REGL_TYPE] DEFAULT ('001'),
[REGL_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_REGL_REGL_STAT] DEFAULT ('001'),
[LETT_NO] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LETT_DATE] [datetime] NULL,
[LETT_OWNR] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STRT_DATE] [datetime] NOT NULL,
[END_DATE] [datetime] NOT NULL,
[TAX_PRCT] [real] NULL,
[DUTY_PRCT] [real] NULL,
[AMNT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[CG$ADEL_REGL]
   ON  [dbo].[Regulation]
   AFTER DELETE
AS 
BEGIN
	IF EXISTS(
	   SELECT * FROM DELETED
	   WHERE REGL_STAT = '002'
	)
	BEGIN
	   RAISERROR ('شما نمی توانید آیین نامه فعال سیستم را پاک کنید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN;
	END;	
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AINS_REGL]
   ON [dbo].[Regulation] 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- در هر لحظه فقط یک آیین نامه فعال برای هر زیرسیستم و نوع هزینه وجود دارد
   -- برای فعال کردن آیین نامه جدید باید آیین نامه قبلی غیرفعال باشد
   IF EXISTS(
      SELECT * FROM dbo.Regulation T, INSERTED S
      WHERE T.SUB_SYS   = S.SUB_SYS
        AND T.TYPE      = S.TYPE
        AND T.REGL_STAT = S.REGL_STAT
        AND T.REGL_STAT = '002'
   )
   BEGIN
      RAISERROR ('شما نمی توانید آیین نامه فعال دیگری ثبت کنید در صورتی که آیین نامه فعال قبلی غیر فعال نشده باشد', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRANSACTION;
   END
   

   -- در زمان ثبت اطلاعات اولیه آیین نامه وضعیت آیین نامه به صورت غیرفعال ثبت میشود
   -- برای فعال کردن آیین نامه بایستی به صورت کاربری با دسترسی فعال کردن آیین نامه انجام شود
   
   -- Insert statements for trigger here
   MERGE dbo.Regulation T
   USING (SELECT * FROM INSERTED) S
   ON (T.[YEAR]    = S.[YEAR]    AND
       T.SUB_SYS   = S.SUB_SYS   AND
       T.[TYPE]    = S.[TYPE]    AND
       T.REGL_STAT = S.REGL_STAT AND
       T.STRT_DATE = S.STRT_DATE AND
       T.END_DATE  = S.END_DATE)
    WHEN MATCHED THEN
      UPDATE
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,CODE      = (SELECT ISNULL(MAX(CODE), 0) + 1 FROM dbo.Regulation)
            ,REGL_STAT = CASE WHEN (SELECT COUNT(*) FROM Regulation WHERE TYPE = S.Type) > 1 THEN '001' ELSE '002'END
            ,T.AMNT_TYPE = ISNULL(s.AMNT_TYPE, '001');
   
   -- کپی برداری از آیین نامه فعال سیستم
   DECLARE C$Regulation CURSOR FOR
      SELECT R.YEAR, R.CODE, I.TYPE FROM Regulation R, INSERTED I
      WHERE R.YEAR = I.YEAR
        AND R.CODE = (SELECT MAX(CODE) FROM Regulation Rt);
   
   DECLARE @ReglYear SMALLINT
          ,@ReglCode INT
          ,@ReglType VARCHAR(3);
          
   OPEN C$Regulation;
   L$NextRow:
   FETCH NEXT FROM C$Regulation
   INTO @ReglYear
       ,@ReglCode
       ,@ReglType;
       
   IF @@FETCH_STATUS <> 0
      GOTO L$EndFetch;
   
   IF @ReglType IN ('001', '002')
   BEGIN
      PRINT @ReglType;
      IF @ReglType = '001'
         IF EXISTS(SELECT * FROM Request_Requester)
            EXEC COPY_RQRQ_P @Reglyear, @ReglCode;
         ELSE
            EXEC CRET_RQRQ_P NULL, NULL;
      ELSE IF @ReglType = '002'
      BEGIN
         IF (SELECT COUNT(*) FROM Regulation WHERE YEAR <> @ReglYear AND CODE <> @ReglCode) = 0 OR
            (SELECT COUNT(*) FROM Regulation WHERE TYPE = '001' AND REGL_STAT = '002') = 0
            PRINT 'Commit Insert Regulation Account';
         ELSE
            EXEC CRET_EXCS_P NULL, @ReglYear, @ReglCode, NULL, NULL, NULL;
      END
   END
   ELSE IF @ReglType = '004'
      PRINT N'کپی از آیین نامه مدارک و مجوزات';
      
   GOTO L$NextRow;
   L$EndFetch:
   CLOSE C$Regulation;
   DEALLOCATE C$Regulation;            
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_REGL]
   ON [dbo].[Regulation] 
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- در هر لحظه فقط یک آیین نامه فعال برای هر زیرسیستم و نوع هزینه وجود دارد
   -- برای فعال کردن آیین نامه جدید باید آیین نامه قبلی غیرفعال باشد
   
   IF EXISTS(
      SELECT * FROM dbo.Regulation T, INSERTED S
      WHERE T.CODE      <> S.CODE
        AND T.SUB_SYS   = S.SUB_SYS
        AND T.TYPE      = S.TYPE
        AND T.REGL_STAT = S.REGL_STAT
        AND T.REGL_STAT = '002'
   )
   BEGIN
      RAISERROR ('شما نمی توانید آیین نامه فعال دیگری ثبت کنید در صورتی که آیین نامه فعال قبلی غیر فعال نشده باشد', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRANSACTION;
   END
   
   -- در زمان ثبت اطلاعات اولیه آیین نامه وضعیت آیین نامه به صورت غیرفعال ثبت میشود
   -- برای فعال کردن آیین نامه بایستی به صورت کاربری با دسترسی فعال کردن آیین نامه انجام شود
   
   -- Insert statements for trigger here
   MERGE dbo.Regulation T
   USING (SELECT * FROM INSERTED) S
   ON (T.[YEAR]    = S.[YEAR]    AND
       T.CODE      = S.CODE      AND
       T.SUB_SYS   = S.SUB_SYS   AND
       T.[TYPE]    = S.[TYPE]    AND
       T.REGL_STAT = S.REGL_STAT AND
       T.STRT_DATE = S.STRT_DATE AND
       T.END_DATE  = S.END_DATE)
    WHEN MATCHED THEN
      UPDATE
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE()
            ,T.AMNT_TYPE = ISNULL(s.AMNT_TYPE, '001');
            
END
;
GO
ALTER TABLE [dbo].[Regulation] ADD CONSTRAINT [CK_REGL_REGL_STAT] CHECK (([REGL_STAT]='002' OR [REGL_STAT]='001'))
GO
ALTER TABLE [dbo].[Regulation] ADD CONSTRAINT [CK_REGL_STRT_DATE] CHECK (([STRT_DATE]<[END_DATE]))
GO
ALTER TABLE [dbo].[Regulation] ADD CONSTRAINT [CK_REGL_END_DATE] CHECK (([STRT_DATE]<[END_DATE]))
GO
ALTER TABLE [dbo].[Regulation] ADD CONSTRAINT [REGL_PK] PRIMARY KEY CLUSTERED  ([YEAR], [CODE]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع واحد پولی', 'SCHEMA', N'dbo', 'TABLE', N'Regulation', 'COLUMN', N'AMNT_TYPE'
GO
