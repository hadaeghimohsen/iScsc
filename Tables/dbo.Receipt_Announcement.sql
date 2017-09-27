CREATE TABLE [dbo].[Receipt_Announcement]
(
[RAID] [bigint] NOT NULL,
[FROM_USER] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[TO_USER] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AMNT] [bigint] NOT NULL,
[RCAN_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_Receipt_Announcement_REC_STAT] DEFAULT ('001'),
[AUTO_DOC] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_Receipt_Announcement_AUTO_DOC] DEFAULT ('001'),
[ACTN_DATE] [datetime] NOT NULL,
[RCAN_RAID] [bigint] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_RCAN]
   ON  [dbo].[Receipt_Announcement]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @ErrorMessage NVARCHAR(MAX);
	DECLARE 	@RAID bigint,
	         @Amnt BIGINT,
	         @FROMUSER varchar(250),
	         @TOUSER varchar(250),
	         @RCANSTAT varchar(3),
	         @AUTODOC varchar(3),
	         @ACTNDATE datetime,
	         @RcanRaid BIGINT;
	       
	BEGIN TRY
	   BEGIN TRAN CG$AINS_RCAN
         DECLARE C$AINS_RCAN CURSOR FOR
            SELECT Raid, Amnt, From_User, To_User, Rcan_Stat, Auto_Doc, Actn_Date, Rcan_Raid FROM INSERTED;
         
         OPEN C$AINS_RCAN;
         FNFC$AINS_RCAN:
         FETCH NEXT FROM C$AINS_RCAN INTO @Raid, @Amnt, @FromUser, @ToUser, @RcanStat, @AutoDoc, @ActnDate, @RcanRaid;
         
         IF @@FETCH_STATUS <> 0
            GOTO CDC$AINS_RCAN;
         
         UPDATE [Receipt_Announcement]
            SET CRET_BY = UPPER(SUSER_NAME())
               ,CRET_DATE = GETDATE()
               --,AMNT = COALESCE(@Amnt, 0)
               ,ACTN_DATE = COALESCE(@ActnDate, GETDATE())
               ,RCAN_STAT = COALESCE(@RcanStat, '001')
               ,AUTO_DOC  = COALESCE(@AutoDoc, '001')
               --,TO_USER = UPPER(SUSER_NAME())
               --,TO_USER   = UPPER(@TOUSER)
               ,RAID = dbo.GNRT_NVID_U()
           WHERE RAID = @RAID
         
         GOTO FNFC$AINS_RCAN;
         CDC$AINS_RCAN:
         CLOSE C$AINS_RCAN;
         DEALLOCATE C$AINS_RCAN;
      COMMIT TRAN CG$AINS_RCAN;
   END TRY
   
   BEGIN CATCH
      IF (SELECT CURSOR_STATUS('local','C$AINS_RCAN')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$AINS_RCAN')) > -1
         BEGIN
          CLOSE C$AINS_RCAN
         END
       DEALLOCATE C$AINS_RCAN
      END
      
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN CG$AINS_RCAN;
   END CATCH
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_RCAN]
   ON  [dbo].[Receipt_Announcement]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @ErrorMessage NVARCHAR(MAX);
	DECLARE 	@RAID bigint,
	         @Amnt BIGINT,
	         @FROMUSER varchar(250),
	         @TOUSER varchar(250),
	         @RCANSTAT varchar(3),
	         @AUTODOC varchar(3),
	         @ACTNDATE datetime;
	       
	BEGIN TRY
	   BEGIN TRAN CG$AUPD_RCAN
         DECLARE C$AUPD_RCAN CURSOR FOR
            SELECT Raid, Amnt, From_User, To_User, Rcan_Stat, Auto_Doc, Actn_Date FROM INSERTED;
         
         OPEN C$AUPD_RCAN;
         FNFC$AUPD_RCAN:
         FETCH NEXT FROM C$AUPD_RCAN INTO @Raid, @Amnt, @FromUser, @ToUser, @RcanStat, @AutoDoc, @ActnDate;
         
         IF @@FETCH_STATUS <> 0
            GOTO CDC$AUPD_RCAN;
         
         IF EXISTS(SELECT * FROM Receipt_Announcement WHERE RAID = @RAID AND FROM_USER <> @FROMUSER)
            RAISERROR(N'این سند برای کاربر دیگر ثبت شده و شما قادر به تغییر آن نیستید. لطفا سند دیگری را ایجاد کنید', 16, 1);
         
         UPDATE [Receipt_Announcement]
            SET MDFY_BY = UPPER(SUSER_NAME())
               ,MDFY_DATE = GETDATE()
           WHERE RAID = @RAID
         
         UPDATE Receipt_Announcement
            SET RCAN_STAT = '001'
          WHERE RAID = (SELECT RCAN_RAID FROM Receipt_Announcement WHERE RAID = @RAID AND RCAN_STAT = '003');
         
         GOTO FNFC$AUPD_RCAN;
         CDC$AUPD_RCAN:
         CLOSE C$AUPD_RCAN;
         DEALLOCATE C$AUPD_RCAN;
      COMMIT TRAN CG$AUPD_RCAN;
   END TRY
   
   BEGIN CATCH
      IF (SELECT CURSOR_STATUS('local','C$AUPD_RCAN')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$AUPD_RCAN')) > -1
         BEGIN
          CLOSE C$AUPD_RCAN
         END
       DEALLOCATE C$AUPD_RCAN
      END
      
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN CG$AUPD_RCAN;
   END CATCH
END
GO
ALTER TABLE [dbo].[Receipt_Announcement] ADD CONSTRAINT [PK_RCAN] PRIMARY KEY CLUSTERED  ([RAID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Receipt_Announcement] ADD CONSTRAINT [FK_RCAN_RCAN] FOREIGN KEY ([RCAN_RAID]) REFERENCES [dbo].[Receipt_Announcement] ([RAID])
GO
