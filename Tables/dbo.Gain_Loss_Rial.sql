CREATE TABLE [dbo].[Gain_Loss_Rial]
(
[GLID] [bigint] NOT NULL CONSTRAINT [DF_Gain_Loss_Rial_GLID] DEFAULT ((0)),
[RQRO_RQST_RQID] [bigint] NULL,
[RQRO_RWNO] [smallint] NULL,
[FIGH_FILE_NO] [bigint] NULL,
[RWNO] [bigint] NULL,
[CONF_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CHNG_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DEBT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AMNT] [int] NULL,
[PRCT] [int] NULL,
[AGRE_DATE] [datetime] NULL,
[PAID_DATE] [datetime] NULL,
[CHNG_RESN] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PRVS_DEBT_DNRM] [int] NULL,
[CRNT_DEBT_DNRM] [int] NULL,
[RESN_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RQRO_RQST_RQID_DNRM] [bigint] NULL,
[RQRO_RWNO_DNRM] [smallint] NULL,
[DPST_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_GLRL]
   ON  [dbo].[Gain_Loss_Rial]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.[Gain_Loss_Rial] T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQRO_RQST_RQID = S.RQRO_RQST_RQID AND
       T.RQRO_RWNO      = S.RQRO_RWNO      AND
       T.FIGH_FILE_NO   = S.FIGH_FILE_NO   AND
       T.GLID           = S.GLID)
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY        = UPPER(SUSER_NAME())
            ,CRET_DATE      = GETDATE()
            ,PRVS_DEBT_DNRM = (SELECT DEBT_DNRM FROM dbo.Fighter WHERE FILE_NO = S.Figh_File_No)
            ,GLID           = dbo.GNRT_NVID_U()
            ,Rwno           = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM dbo.Gain_Loss_Rial WHERE FIGH_FILE_NO = S.Figh_File_No);   
   
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_GLRL]
   ON  [dbo].[Gain_Loss_Rial]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.[Gain_Loss_Rial] T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQRO_RQST_RQID = S.RQRO_RQST_RQID AND
       T.RQRO_RWNO      = S.RQRO_RWNO      AND
       T.FIGH_FILE_NO   = S.FIGH_FILE_NO   AND
       T.GLID           = S.GLID)
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY        = UPPER(SUSER_NAME())
            ,MDFY_DATE      = GETDATE()
            ,CRNT_DEBT_DNRM = CASE S.Conf_Stat 
                                 WHEN '002' THEN 
                                    S.PRVS_DEBT_DNRM - 
                                    CASE S.CHNG_TYPE 
                                       WHEN '001' THEN -- افزایش بدهی
                                          CASE S.DEBT_TYPE
                                             WHEN '000' THEN -1 * S.AMNT 
                                             WHEN '001' THEN -1 * S.AMNT 
                                             WHEN '002' THEN 0
                                          END                                          
                                       WHEN '002' THEN -- کاهش بدهی
                                          CASE S.DEBT_TYPE
                                             WHEN '003' THEN S.AMNT 
                                             WHEN '004' THEN 0
                                             WHEN '005' THEN S.AMNT 
                                          END                                          
                                    END 
                                 ELSE NULL 
                              END
            ,AGRE_DATE      = CASE S.Conf_Stat WHEN '002' THEN GETDATE() ELSE NULL END ;
   
   /* 1395/03/29 * باید برای ذخیره کردن کد های مربوط به تغییرات ریالی در جدول حسابداری اطلاعات ذخیره شود */
   -- ثبت اطلاعات هزینه های ثبت شده در جدول حسابداری برای باشگاه
	--IF EXISTS(
	--   SELECT *
	--     FROM dbo.Gain_Loss_Rial T, INSERTED S
	--    WHERE T.RQRO_RQST_RQID = S.RQRO_RQST_RQID AND             
 --            T.RQRO_RWNO      = S.RQRO_RWNO      AND
 --            T.FIGH_FILE_NO   = S.FIGH_FILE_NO   AND
 --            T.CONF_STAT      = '002'            AND -- تایید پرداخت
 --            T.DEBT_TYPE      IN ('000', '002', '004', '005') 
	--)
	--BEGIN	
	--   DECLARE @Rwno BIGINT
	--          ,@AcdtRwno INT
	--          ,@ActnDate DATETIME
	--          ,@RegnPrvnCntyCode VARCHAR(3)
	--          ,@RegnPrvnCode VARCHAR(3)
	--          ,@RegnCode VARCHAR(3)
	--          ,@ClubCode BIGINT
	--          ,@ExpnAmnt BIGINT
	--          ,@Rqid BIGINT
	--          ,@AmntType VARCHAR(3);	   
	          
	--   SET @ActnDate = GETDATE();
	--   SELECT @RegnPrvnCntyCode = R.REGN_PRVN_CNTY_CODE
	--         ,@RegnPrvnCode = R.REGN_PRVN_CODE
	--         ,@RegnCode = R.REGN_CODE
	--         ,@ClubCode = F.CLUB_CODE_DNRM
	--         ,@ExpnAmnt = P.AMNT
	--         ,@Rqid = R.RQID
	--         ,@AmntType = CASE P.DEBT_TYPE 
	--                        WHEN '000' THEN '001'
	--                        WHEN '002' THEN '002' 
	--                        WHEN '004' THEN '001' 
	--                        WHEN '005' THEN '002'
	--                      END 
	--     FROM Request R, dbo.Gain_Loss_Rial P, INSERTED G, dbo.Fighter F
	--    WHERE R.RQID = P.RQRO_RQST_RQID
	--      AND P.RQRO_RQST_RQID = G.Rqro_Rqst_Rqid
	--      AND p.FIGH_FILE_NO = f.FILE_NO;
      
 --     --PRINT @ExpnAmnt;
      
	--   IF NOT EXISTS(
	--      SELECT *
	--        FROM Request R, Account_Detail ad
	--       WHERE R.RQID = Ad.PYMT_RQST_RQID
	--         AND R.RQID = @Rqid
	--   )  
	--   BEGIN 
	--      EXEC dbo.INS_ACTN_P @RegnPrvnCntyCode, @RegnPrvnCode, @RegnCode, @ClubCode, 0, @AmntType, @ActnDate, @Rwno OUT;
	--      EXEC dbo.INS_ACDT_P @RegnPrvnCntyCode, @RegnPrvnCode, @RegnCode, @ClubCode, @Rwno, @ExpnAmnt, @AmntType, @ActnDate, NULL, @Rqid, NULL, @AcdtRwno OUT;
	--   END
	--END         
   
   UPDATE dbo.Fighter
      SET CONF_STAT = CONF_STAT
   WHERE EXISTS(
      SELECT *
        FROM INSERTED i
       WHERE i.figh_file_no = File_No
   );
END
;
GO
ALTER TABLE [dbo].[Gain_Loss_Rial] ADD CONSTRAINT [PK_GLRL] PRIMARY KEY CLUSTERED  ([GLID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Gain_Loss_Rial] ADD CONSTRAINT [FK_GLRL_FIGH] FOREIGN KEY ([FIGH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO])
GO
ALTER TABLE [dbo].[Gain_Loss_Rial] ADD CONSTRAINT [FK_GLRL_RQDN] FOREIGN KEY ([RQRO_RQST_RQID_DNRM], [RQRO_RWNO_DNRM]) REFERENCES [dbo].[Request_Row] ([RQST_RQID], [RWNO])
GO
ALTER TABLE [dbo].[Gain_Loss_Rial] ADD CONSTRAINT [FK_GLRL_RQRO] FOREIGN KEY ([RQRO_RQST_RQID], [RQRO_RWNO]) REFERENCES [dbo].[Request_Row] ([RQST_RQID], [RWNO]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع سپرده گذاری
افزایش سپرده گذاری
برداشت سپرده گذاری', 'SCHEMA', N'dbo', 'TABLE', N'Gain_Loss_Rial', 'COLUMN', N'DPST_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'درصد تغییراتی ریالی', 'SCHEMA', N'dbo', 'TABLE', N'Gain_Loss_Rial', 'COLUMN', N'PRCT'
GO
