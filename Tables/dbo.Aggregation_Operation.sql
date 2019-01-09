CREATE TABLE [dbo].[Aggregation_Operation]
(
[CODE] [bigint] NOT NULL,
[REGN_PRVN_CNTY_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Aggregation_Operation_REGN_PRVN_CNTY_CODE] DEFAULT ('001'),
[REGN_PRVN_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REGN_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RQTP_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RQTT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REGL_YEAR] [smallint] NULL,
[REGL_CODE] [int] NULL,
[MTOD_CODE] [bigint] NULL,
[CTGY_CODE] [bigint] NULL,
[COCH_FILE_NO] [bigint] NULL,
[CBMT_CODE] [bigint] NULL,
[OPRT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OPRT_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Aggregation_Operation_OPRT_STAT] DEFAULT ('001'),
[FROM_DATE] [date] NULL,
[TO_DATE] [date] NULL,
[NUMB_OF_ATTN_MONT] [int] NULL,
[NUMB_MONT_OFFR] [int] NULL,
[NEW_CBMT_CODE] [bigint] NULL,
[NEW_MTOD_CODE] [bigint] NULL,
[NEW_CTGY_CODE] [bigint] NULL,
[AGOP_DESC] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UNIT_BLOK_CNDO_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UNIT_BLOK_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UNIT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_AGOP]
   ON  [dbo].[Aggregation_Operation]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Aggregation_Operation T
   USING (SELECT * FROM INSERTED) S
   ON (
      T.REGN_PRVN_CODE = S.Regn_Prvn_Code AND
      T.REGN_CODE      = S.Regn_Code      AND
      T.OPRT_TYPE      = S.Oprt_Type      AND
      T.RQTT_CODE      = S.Rqtt_Code      AND
      T.CODE           = S.Code
   )
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,CODE = dbo.GNRT_NVID_U()
            ,REGL_YEAR = (SELECT YEAR FROM dbo.Regulation WHERE TYPE = '001' AND REGL_STAT = '002' AND SUB_SYS = 1)
            ,REGL_CODE = (SELECT CODE FROM dbo.Regulation WHERE TYPE = '001' AND REGL_STAT = '002' AND SUB_SYS = 1);
END
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
CREATE TRIGGER [dbo].[CG$AUPD_AGOP]
   ON  [dbo].[Aggregation_Operation]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   IF EXISTS(
      SELECT *
        FROM INSERTED I, DELETED D
       WHERE I.Code = D.Code
         AND D.Oprt_Stat = '003'
         AND I.Oprt_Stat != '003'
   )
   BEGIN
      RAISERROR (N'عملیات تجمعی که انصراف خورده اند دیگر قادر به ادامه کار نیستند.', 16, 1);
      RETURN;
   END
   
    -- Insert statements for trigger here
   MERGE dbo.Aggregation_Operation T
   USING (SELECT * FROM INSERTED) S
   ON (
      T.REGN_PRVN_CODE = S.Regn_Prvn_Code AND
      T.REGN_CODE      = S.Regn_Code      AND
      T.OPRT_TYPE      = S.Oprt_Type      AND
      T.RQTT_CODE      = S.Rqtt_Code      AND
      T.CODE           = S.Code
   )
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE();
            --,REGN_PRVN_CNTY_CODE = (SELECT r.PRVN_CNTY_CODE FROM dbo.Region R WHERE r.CODE = S.Regn_Code)
            --,REGN_PRVN_CODE = (SELECT r.PRVN_CODE FROM dbo.Region R WHERE r.CODE = S.Regn_Code)
            --,MTOD_CODE = (SELECT c.MTOD_CODE FROM dbo.Category_Belt c WHERE c.CODE = S.Ctgy_Code)
            --,COCH_FILE_NO = (SELECT ISNULL(c.COCH_FILE_NO, S.Coch_File_No) FROM dbo.Club_Method c WHERE c.CODE = s.Cbmt_Code);
   
   -- آماده سازی پرونده های مورد نیاز برای انجام عملیات دوره ای
   DECLARE C$RunOprt CURSOR FOR
      SELECT I.Code
        FROM INSERTED  I, DELETED D
       WHERE I.Code = D.Code
         AND I.Oprt_Stat = '002'
         AND D.Oprt_Stat = '001';
   
   DECLARE @Code BIGINT;
   
   OPEN C$RunOprt;
   L$FC$RunOprt:
   FETCH NEXT FROM C$RunOprt INTO @Code;
   
   IF @@FETCH_STATUS <> 0
      GOTO L$EC$RunOprt;
      
   BEGIN
      DECLARE C$Figh CURSOR FOR
         SELECT FILE_NO, ao.OPRT_TYPE
           FROM dbo.Fighter F, dbo.Aggregation_Operation Ao
          WHERE Ao.CODE = @Code
            AND F.REGN_PRVN_CNTY_CODE = Ao.REGN_PRVN_CNTY_CODE
            AND f.CONF_STAT = '002' -- تایید شده باشد            
            AND f.ACTV_TAG_DNRM >= '101'
            AND 1 = (
               CASE 
                  WHEN Ao.OPRT_TYPE IN ( '001' , '002', '003', '006' )
                     AND F.FIGH_STAT = '002' -- ازاد باشد
                     AND F.FGPB_TYPE_DNRM IN ('001')
                     AND EXISTS(
                        SELECT *
                          FROM dbo.Member_Ship ms, dbo.Fighter_Public fp
                         WHERE ms.FIGH_FILE_NO = f.FILE_NO
                           AND ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
                           AND ms.FGPB_RWNO_DNRM = fp.RWNO
                           AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
                           AND ms.RECT_CODE = '004'
                           AND ms.VALD_TYPE = '002'
                           AND CAST(ms.STRT_DATE as DATE) <= CAST(GETDATE() AS DATE)
                           AND (ms.Numb_Of_Attn_Mont = 0 OR ms.Numb_Of_Attn_Mont > ms.Sum_Attn_Mont_Dnrm)
                           AND (CAST(GETDATE() AS DATE) BETWEEN CAST(ms.Strt_Date AS DATE) AND CAST(ms.End_Date AS DATE) )
                           AND (ao.REGN_CODE IS NULL OR Fp.REGN_CODE = Ao.REGN_CODE AND Fp.REGN_PRVN_CODE = Ao.REGN_PRVN_CODE)
                           AND (ao.MTOD_CODE IS NULL OR fp.MTOD_CODE = ao.MTOD_CODE)
                           AND (ao.CTGY_CODE IS NULL OR fp.CTGY_CODE = ao.CTGY_CODE)
                           AND (ao.COCH_FILE_NO IS NULL OR fp.COCH_FILE_NO = ao.COCH_FILE_NO)
                           AND (ao.CBMT_CODE is NULL OR fp.CBMT_CODE = ao.CBMT_CODE)
                           AND (ao.UNIT_BLOK_CNDO_CODE IS NULL OR fp.UNIT_BLOK_CNDO_CODE = ao.UNIT_BLOK_CNDO_CODE)
                           AND (ao.UNIT_BLOK_CODE IS NULL OR fp.UNIT_BLOK_CODE = ao.UNIT_BLOK_CODE)
                           AND (ao.UNIT_CODE IS NULL OR fp.UNIT_CODE = ao.UNIT_CODE)
                     )                         
                  THEN 1                         
                  WHEN   Ao.OPRT_TYPE IN ( '004' )
                     AND F.FGPB_TYPE_DNRM IN ('001')
                     AND EXISTS(
                        SELECT *
                          FROM dbo.Member_Ship ms, dbo.Fighter_Public fp
                         WHERE ms.FIGH_FILE_NO = f.FILE_NO
                           AND ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
                           AND ms.FGPB_RWNO_DNRM = fp.RWNO
                           AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
                           AND ms.RECT_CODE = '004'
                           AND ms.VALD_TYPE = '002'
                           AND CAST(ms.STRT_DATE as DATE) <= CAST(GETDATE() AS DATE)
                           AND (ms.Numb_Of_Attn_Mont = 0 OR ms.Numb_Of_Attn_Mont > ms.Sum_Attn_Mont_Dnrm)
                           AND (CAST(GETDATE() AS DATE) BETWEEN CAST(ms.Strt_Date AS DATE) AND CAST(ms.End_Date AS DATE) )
                           AND (ao.REGN_CODE IS NULL OR Fp.REGN_CODE = Ao.REGN_CODE AND Fp.REGN_PRVN_CODE = Ao.REGN_PRVN_CODE)
                           AND (ao.MTOD_CODE IS NULL OR fp.MTOD_CODE = ao.MTOD_CODE)
                           AND (ao.CTGY_CODE IS NULL OR fp.CTGY_CODE = ao.CTGY_CODE)
                           AND (ao.COCH_FILE_NO IS NULL OR fp.COCH_FILE_NO = ao.COCH_FILE_NO)
                           AND (ao.CBMT_CODE is NULL OR fp.CBMT_CODE = ao.CBMT_CODE)
                     )                     
                  THEN 1                         
                  ELSE 0
               END
            );
      
      DECLARE @fileno BIGINT,
              @MbspRwno SMALLINT,
              @OprtType VARCHAR(3);
      
      OPEN C$figh;
      L$FC$figh:
      FETCH NEXT FROM C$figh INTO @fileno, @OprtType;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EC$Figh;
      
      SET @MbspRwno = NULL;
      IF @OprtType = '004'
      BEGIN
         SELECT @MbspRwno = ms.RWNO
           FROM dbo.Member_Ship ms, dbo.Fighter_Public fp, dbo.Aggregation_Operation ao
          WHERE ms.FIGH_FILE_NO = @FileNo
            AND ao.CODE = @Code
            AND ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
            AND ms.FGPB_RWNO_DNRM = fp.RWNO
            AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
            --AND fp.MTOD_CODE = ao.MTOD_CODE
            AND fp.CTGY_CODE = ISNULL(ao.CTGY_CODE, fp.CTGY_CODE)
            AND fp.COCH_FILE_NO = ao.COCH_FILE_NO
            AND fp.CBMT_CODE = ao.CBMT_CODE
            AND ms.VALD_TYPE = '002'
            AND ms.RECT_CODE = '004'
            AND CAST(ms.STRT_DATE as DATE) <= CAST(GETDATE() AS DATE)
            AND (ms.Numb_Of_Attn_Mont = 0 OR ms.Numb_Of_Attn_Mont > ms.Sum_Attn_Mont_Dnrm)
            AND (CAST(GETDATE() AS DATE) BETWEEN CAST(ms.Strt_Date AS DATE) AND CAST(ms.End_Date AS DATE) );      
      END
      
      INSERT INTO dbo.Aggregation_Operation_Detail( AGOP_CODE , RWNO , FIGH_FILE_NO , MBSP_RWNO, ATTN_TYPE)
      VALUES  ( @Code ,  0 , @fileno , @MbspRwno, '001');
      
      GOTO L$FC$Figh;
      L$EC$figh:   
      CLOSE C$figh;
      DEALLOCATE C$figh;
   END
   
   GOTO L$FC$RunOprt;
   L$EC$RunOprt:
   CLOSE C$RunOprt;
   DEALLOCATE C$RunOprt;
   
   -- آماده سازی پرونده های مورد نیاز برای پایانی کردن درخواست های ایجاد شده
   DECLARE C$RunOprt002004 CURSOR FOR
      SELECT I.Code
        FROM INSERTED  I, DELETED D
       WHERE I.Code = D.Code
         AND I.Oprt_Stat = '004'
         AND D.Oprt_Stat = '002';
   
   --DECLARE @Code BIGINT;
   
   OPEN C$RunOprt002004;
   L$FC$RunOprt002004:
   FETCH NEXT FROM C$RunOprt002004 INTO @Code;
   
   IF @@FETCH_STATUS <> 0
      GOTO L$EC$RunOprt002004;
      
   BEGIN
      DECLARE C$Figh002004 CURSOR FOR
         SELECT FIGH_FILE_NO, REC_STAT, RQST_RQID
           FROM dbo.Aggregation_Operation_Detail Ao
          WHERE Ao.AGOP_CODE = @Code;

      
      DECLARE @RecStat BIGINT
             ,@RqstRqid BIGINT;
      
      OPEN C$figh002004;
      L$FC$figh002004:
      FETCH NEXT FROM C$figh002004 INTO @fileno, @RecStat, @RqstRqid;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EC$Figh002004;
      
      IF @RecStat = '002'
      BEGIN
         DECLARE @X XML;
         SELECT @X =(
          SELECT @Code AS '@agopcode'
                ,@FileNo AS '@fighfileno'            
          FOR XML PATH('Aodt'), ROOT('Agop')
         );
         EXEC AGOP_ERQT_P @X;
      END
      ELSE
      BEGIN
         IF NOT EXISTS(SELECT * FROM dbo.Request WHERE RQID = @RqstRqid AND RQST_STAT IN ( '003', '002' ) )
         BEGIN
            SELECT @X =(
             SELECT @RqstRqid AS '@rqid'
             FOR XML PATH('Request'), ROOT('Process')
            );
            EXEC dbo.CNCL_RQST_F @X;
         END
      END
      
      GOTO L$FC$Figh002004;
      L$EC$figh002004:   
      CLOSE C$figh002004;
      DEALLOCATE C$figh002004;
   END
   
   GOTO L$FC$RunOprt002004;
   L$EC$RunOprt002004:
   CLOSE C$RunOprt002004;
   DEALLOCATE C$RunOprt002004;
   
   -- انصراف عملیات و انصراف درخواست های ایجاد شده
   DECLARE C$RunOprt002003 CURSOR FOR
      SELECT I.Code
        FROM INSERTED  I, DELETED D
       WHERE I.Code = D.Code
         AND I.Oprt_Stat = '003'
         AND D.Oprt_Stat = '002';
   
   OPEN C$RunOprt002003;
   L$FC$RunOprt002003:
   FETCH NEXT FROM C$RunOprt002003 INTO @Code;
   
   IF @@FETCH_STATUS <> 0
      GOTO L$EC$RunOprt002003;
      
   BEGIN
      DECLARE C$Figh002003 CURSOR FOR
         SELECT FIGH_FILE_NO, REC_STAT, RQST_RQID
           FROM dbo.Aggregation_Operation_Detail Ao
          WHERE Ao.AGOP_CODE = @Code;
      
      OPEN C$Figh002003;
      L$FC$figh002003:
      FETCH NEXT FROM C$figh002003 INTO @fileno, @RecStat, @RqstRqid;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EC$Figh002003;
      
      BEGIN         
         IF NOT EXISTS(SELECT * FROM dbo.Request WHERE RQID = @RqstRqid AND RQST_STAT IN ( '003', '002' ))
         BEGIN
            SELECT @X =(
             SELECT @RqstRqid AS '@rqid'
             FOR XML PATH('Request'), ROOT('Process')
            );
            EXEC dbo.CNCL_RQST_F @X;
         END
      END
      
      GOTO L$FC$Figh002003;
      L$EC$Figh002003:   
      CLOSE C$figh002003;
      DEALLOCATE C$figh002003;
   END
   
   GOTO L$FC$RunOprt002003;
   L$EC$RunOprt002003:
   CLOSE C$RunOprt002003;
   DEALLOCATE C$RunOprt002003;   
END
GO
ALTER TABLE [dbo].[Aggregation_Operation] ADD CONSTRAINT [PK_AGOP] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Aggregation_Operation] ADD CONSTRAINT [FK_AGOP_CBMT] FOREIGN KEY ([CBMT_CODE]) REFERENCES [dbo].[Club_Method] ([CODE])
GO
ALTER TABLE [dbo].[Aggregation_Operation] ADD CONSTRAINT [FK_AGOP_CTGY] FOREIGN KEY ([CTGY_CODE]) REFERENCES [dbo].[Category_Belt] ([CODE])
GO
ALTER TABLE [dbo].[Aggregation_Operation] ADD CONSTRAINT [FK_AGOP_FIGH] FOREIGN KEY ([COCH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO])
GO
ALTER TABLE [dbo].[Aggregation_Operation] ADD CONSTRAINT [FK_AGOP_MTOD] FOREIGN KEY ([MTOD_CODE]) REFERENCES [dbo].[Method] ([CODE])
GO
ALTER TABLE [dbo].[Aggregation_Operation] ADD CONSTRAINT [FK_AGOP_REGL] FOREIGN KEY ([REGL_YEAR], [REGL_CODE]) REFERENCES [dbo].[Regulation] ([YEAR], [CODE])
GO
ALTER TABLE [dbo].[Aggregation_Operation] ADD CONSTRAINT [FK_AGOP_REGN] FOREIGN KEY ([REGN_PRVN_CNTY_CODE], [REGN_PRVN_CODE], [REGN_CODE]) REFERENCES [dbo].[Region] ([PRVN_CNTY_CODE], [PRVN_CODE], [CODE])
GO
ALTER TABLE [dbo].[Aggregation_Operation] ADD CONSTRAINT [FK_AGOP_RQTP] FOREIGN KEY ([RQTP_CODE]) REFERENCES [dbo].[Request_Type] ([CODE])
GO
ALTER TABLE [dbo].[Aggregation_Operation] ADD CONSTRAINT [FK_AGOP_RQTT] FOREIGN KEY ([RQTT_CODE]) REFERENCES [dbo].[Requester_Type] ([CODE])
GO
EXEC sp_addextendedproperty N'MS_Description', N'ساعت کلاسی جدید', 'SCHEMA', N'dbo', 'TABLE', N'Aggregation_Operation', 'COLUMN', N'NEW_CBMT_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'رسته جدید', 'SCHEMA', N'dbo', 'TABLE', N'Aggregation_Operation', 'COLUMN', N'NEW_CTGY_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'سبک جدید', 'SCHEMA', N'dbo', 'TABLE', N'Aggregation_Operation', 'COLUMN', N'NEW_MTOD_CODE'
GO
