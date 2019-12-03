CREATE TABLE [dbo].[Request_Row]
(
[REGN_PRVN_CNTY_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REGN_PRVN_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REGN_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RQTP_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RQTT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RQST_RQID] [bigint] NOT NULL,
[RWNO] [smallint] NOT NULL CONSTRAINT [DF_RQRO_RWNO] DEFAULT ((0)),
[FIGH_FILE_NO] [bigint] NULL,
[RECD_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_RQRO_RECD_STAT] DEFAULT ('002'),
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
CREATE TRIGGER [dbo].[CG$ADEL_RQRO]
   ON  [dbo].[Request_Row]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   DECLARE C#ADEL_RQRO CURSOR FOR 
      SELECT Rqst_Rqid, Figh_File_No FROM DELETED;
   
   DECLARE @RqstRqid BIGINT,
           @FileNo   BIGINT,
           @ErorMesg NVARCHAR(250);
           
   OPEN C#ADEL_RQRO;
   L$NextRow:
   FETCH NEXT FROM C#ADEL_RQRO INTO @RqstRqid, @FileNo;
   
   IF @@FETCH_STATUS <> 0
      GOTO L$EndFetch;
   
   UPDATE Fighter
      SET RQST_RQID = NULL
         ,FIGH_STAT = '002'      
     WHERE FILE_NO = @FileNo;

   GOTO L$NextRow;
   L$EndFetch:
   CLOSE C#ADEL_RQRO;
   DEALLOCATE C#ADEL_RQRO;
END;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AINS_RQRO]
   ON  [dbo].[Request_Row]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   
   DECLARE C#FileNo CURSOR FOR 
      SELECT Rqst_Rqid, Figh_File_No FROM INSERTED;
   
   DECLARE @RqstRqid BIGINT,
           @RqtpDesc NVARCHAR(250),
           @FileNo   BIGINT,
           @Name     NVARCHAR(500),
           @MustLock VARCHAR(3),
           @ErorMesg NVARCHAR(250);
           
   OPEN C#FileNo;
   L$NextRow:
   FETCH NEXT FROM C#FileNo INTO @RqstRqid, @FileNo;
   
   IF @@FETCH_STATUS <> 0
      GOTO L$EndFetch;
      
   SELECT @MustLock = rt.MUST_LOCK
     FROM Request_Type rt, Request r
    WHERE r.RQID = @RqstRqid
      AND rt.CODE = r.RQTP_CODE;
   
   IF NOT EXISTS( 
      SELECT * FROM Request
      WHERE REGN_PRVN_CODE + REGN_CODE = (
         SELECT REGN_PRVN_CODE + REGN_CODE FROM Fighter WHERE FILE_NO = @FileNo
      )
   )
   BEGIN
      SELECT @ErorMesg = N'هنرجو مورد نظر در "ناحیه ' + REGN_CODE + N' "  می باشد و نمی توانید در درخواستی با ناحیه دیگری ثبت نمایید.'
        FROM Fighter 
       WHERE FILE_NO = @FileNo;
       
      RAISERROR (@ErorMesg, -- Message text.
                 16, -- Severity.
                 1   -- State.
                );
      ROLLBACK TRANSACTION;
   END
   --ELSE IF NOT EXISTS(SELECT * FROM Fighter WHERE FILE_NO = @FileNo AND FGPB_TYPE_DNRM IN ('002', '003')) AND NOT EXISTS(SELECT * FROM Request WHERE RQID = @RqstRqid AND RQTP_CODE IN ('009', '001', '016', '002', '011', '013', '014', '022', '023', '025')) AND NOT EXISTS(SELECT * FROM Member_Ship WHERE FIGH_FILE_NO = @FileNo AND [TYPE] = '001' AND RECT_CODE = '004' AND CAST(END_DATE AS DATE) >= CAST(GETDATE() AS DATE))
   --BEGIN
   --   SELECT @ErorMesg = N' تاریخ اعتبار کارت عضویت هنرجو ' + NAME_DNRM + N' به پایان رسیده. جهت تمدید کارت عضویت اقدام نمایید. '
   --     FROM Fighter 
   --    WHERE FILE_NO = @FileNo;
       
   --   RAISERROR (@ErorMesg, -- Message text.
   --              16, -- Severity.
   --              1   -- State.
   --             );
   --   ROLLBACK TRANSACTION;
   --END
   ELSE IF @MustLock = '002' -- اگر درخواست از نوعی باشد که هنرجو باید قفل شود باید چک کنیم که درگیر فرآیندی دیگری نباشد
      AND  
      EXISTS(
         SELECT * FROM Fighter f
         WHERE f.FILE_NO = @FileNo 
           AND f.FIGH_STAT = '001' -- Lock
           AND f.RQST_RQID <> @RqstRqid
           AND 
           EXISTS(
            SELECT * FROM Request r, Request_Row rr
            WHERE f.RQST_RQID = r.RQID
              AND r.RQST_STAT = '001'
              AND rr.RQST_RQID = r.RQID
              AND rr.RECD_STAT = '002'
           )
      )
      AND 
      -- 1396/03/01
      /* اگر درخواستی پیرو درخواستی که هنرجو در آن قفل باشد بایستی سیستم این کار را انجام دهد */
      NOT EXISTS(
         SELECT *
           FROM dbo.Fighter
          WHERE FILE_NO = @FileNo
            AND RQST_RQID = dbo.GET_NSPR_U('<Request nstptype="001" rqid="' + CAST(@RqstRqid AS VARCHAR(20)) + '"/>')          
      )
   BEGIN      
      SELECT @RqstRqid = r.RQID
            ,@RqtpDesc = rt.RQTP_DESC
            ,@Name     = f.NAME_DNRM
      FROM Fighter f, Request r, Request_Type rt
      WHERE f.RQST_RQID = r.RQID
        AND r.RQTP_CODE = rt.CODE
        AND f.FILE_NO   = @FileNo;
      SET @ErorMesg = N'هنرجو مورد نظر به شماره پرونده ' + CAST(@FileNo AS VARCHAR) + N' به نام ' + @Name + N' در فرآیند ' + @RqtpDesc + N' به شماره درخواست ' + CAST(@RqstRqid AS VARCHAR) + N' درگیر می باشد';
      RAISERROR (@ErorMesg, -- Message text.
                 16, -- Severity.
                 1   -- State.
                );
      ROLLBACK TRANSACTION;   
   END
   ELSE IF EXISTS(SELECT * FROM Fighter WHERE FILE_NO = @FileNo AND ISNULL(ACTV_TAG_DNRM, '101') <= '100') AND EXISTS(SELECT * FROM Request WHERE RQID = @RqstRqid AND RQTP_CODE NOT IN ('014', '002'))
   BEGIN
      SELECT @ErorMesg = N' هنرجو ' + NAME_DNRM + N' به دلایلی از سیستم به صورت موقت خارج شده لطفا به سرپرستی اطلاع دهید '
        FROM Fighter 
       WHERE FILE_NO = @FileNo;
       
      RAISERROR (@ErorMesg, -- Message text.
                 16, -- Severity.
                 1   -- State.
                );
      ROLLBACK TRANSACTION;
   END
   -- پایان مهلت بدهی هنرجو
   ELSE IF dbo.CHK_DEBT_U('<Fighter fileno="' + CAST(@FileNo AS VARCHAR(14)) + '"/>') = 0 AND EXISTS(SELECT * FROM Request WHERE RQID = @RqstRqid AND RQTT_CODE NOT IN ('004'))
   BEGIN
      SELECT @ErorMesg = N'هشدار!!!' + CHAR(10) + 
                         sxdc.DOMN_DESC + N' ' + NAME_DNRM + 
                         N' مهلت پرداخت بدهی ما به پایان رسیده است.' + CHAR(10) +
                         N'لطفا جهت تسویه بدهی خود اقدام فرمایید'
        FROM dbo.Fighter F, dbo.D$SXDC sxdc
       WHERE FILE_NO = @FileNo
         AND F.SEX_TYPE_DNRM = sxdc.VALU;

      RAISERROR (@ErorMesg, 
               --N'خطا 4 - این شماره پرونده فاقد اعتبار عضویت باشگاه می باشد. لطفا اول جهت تمدید قرارداد اقدام کنید سپس حضوری ثبت کنید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
   END;
   
   DECLARE @RegnPrvnCntyCode VARCHAR(3),
           @RegnPrvnCode VARCHAR(3),
           @RegnCode VARCHAR(3),
           @RqtpCode VARCHAR(3),
           @RqttCode VARCHAR(3);
   
   SELECT @RegnPrvnCntyCode = REGN_PRVN_CNTY_CODE
         ,@RegnPrvnCode = REGN_PRVN_CODE
         ,@RegnCode = REGN_CODE
         ,@RqtpCode = RQTP_CODE
         ,@RqttCode = RQTT_CODE
     FROM dbo.Request
    WHERE RQID = @RqstRqid;        
   
   
   MERGE dbo.Request_Row T   
   USING (SELECT * FROM INSERTED) S
   ON (T.RQST_RQID = S.RQST_RQID AND 
       T.RWNO      = S.RWNO)
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,REGN_PRVN_CNTY_CODE = @RegnPrvnCntyCode
            ,REGN_PRVN_CODE = @RegnPrvnCode
            ,REGN_CODE = @RegnCode
            ,RQTP_CODE = @RqtpCode
            ,RQTT_CODE = @RqttCode
            ,RWNO      = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM REQUEST_ROW WHERE RQST_RQID = S.RQST_RQID);
            
   -- 1396/03/01
   IF EXISTS(
         SELECT *
           FROM dbo.Fighter
          WHERE FILE_NO = @FileNo
            AND RQST_RQID IS NULL
            AND FIGH_STAT = '002'
      ) OR
      /* اگر درخواستی پیرو درخواستی که هنرجو در آن قفل باشد بایستی سیستم این کار را انجام دهد */
      NOT EXISTS(
         SELECT *
           FROM dbo.Fighter
          WHERE FILE_NO = @FileNo
            AND RQST_RQID IS NOT NULL
            AND FIGH_STAT = '001'
            AND RQST_RQID = dbo.GET_NSPR_U('<Request nstptype="001" rqid="' + CAST(@RqstRqid AS VARCHAR(20)) + '"/>')          
      )
   BEGIN
      -- LOCK FIGHTER IF EXISTS IN REQUEST_ROW
      MERGE dbo.Fighter T
      USING (SELECT I.FIGH_FILE_NO, @MustLock As MUST_LOCK, I.RQST_RQID, I.RECD_STAT
               FROM INSERTED I, Request R 
              WHERE I.RQST_RQID    = R.RQID 
                AND R.RQST_STAT    = '001'
                AND I.FIGH_FILE_NO = @FileNo) S
      ON (T.FILE_NO   = S.FIGH_FILE_NO AND
          MUST_LOCK = '002')
      WHEN MATCHED THEN
         UPDATE
            SET RQST_RQID = CASE WHEN S.RECD_STAT = '001' THEN NULL ELSE S.RQST_RQID END
               ,FIGH_STAT = CASE WHEN S.RECD_STAT = '001' THEN '002' ELSE '001' END;
   END;
   
   DECLARE @X XML;
   SELECT @X = (
   SELECT r.RQID AS '@rqid'
         ,r.RQTP_CODE AS '@rqtpcode'
         ,r.RQTT_CODE AS '@rqttcode'
         ,rr.RWNO AS 'Request_Row/@rwno'
     FROM Request R, Request_Row rr
    WHERE r.RQID = @RqstRqid 
      AND r.RQID = rr.RQST_RQID
      AND Rr.FIGH_FILE_NO = @FileNo
    FOR XML PATH('Request'), ROOT('Process'));
   EXEC CMN_DCMT_P @X;
   
   GOTO L$NextRow;
   L$EndFetch:
   CLOSE C#FileNo;
   DEALLOCATE C#FileNo;
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_RQRO]
   ON  [dbo].[Request_Row]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   DECLARE C#AUPD_RQRO CURSOR FOR 
      SELECT Rqst_Rqid, Figh_File_No, RECD_STAT, RWNO FROM INSERTED;
   
   DECLARE @RqstRqid BIGINT,
           @RqtpDesc NVARCHAR(250),
           @FileNo   BIGINT,
           @RecdStat VARCHAR(3),
           @MustLock VARCHAR(3),
           @ErorMesg NVARCHAR(250),
           @Rwno     SMALLINT,
           @X        XML,
           @RqtpCode VARCHAR(3),
           @RqttCode VARCHAR(3);
           
   OPEN C#AUPD_RQRO;
   L$NextRow:
   FETCH NEXT FROM C#AUPD_RQRO INTO @RqstRqid, @FileNo, @RecdStat, @Rwno;
   
   IF @@FETCH_STATUS <> 0
      GOTO L$EndFetch;
   
   SELECT @MustLock = rt.MUST_LOCK
         ,@RqtpCode = r.RQTP_CODE
         ,@RqttCode = r.RQTT_CODE
     FROM Request_Type rt, Request r
    WHERE r.RQID = @RqstRqid
      AND rt.CODE = r.RQTP_CODE;

   SELECT @X = (
      SELECT @RqstRqid AS '@rqid'
            ,@RqtpCode AS '@rqtpcode'
            ,@RqttCode AS '@rqttcode'
            ,@Rwno     AS 'Request_Row/@rwno'
         FOR XML PATH('Request'), ROOT('Process')
   );
   EXEC CMN_DCMT_P @X;
   
   IF NOT EXISTS( 
      SELECT * FROM Request
      WHERE REGN_PRVN_CODE + REGN_CODE = (
         SELECT REGN_PRVN_CODE + REGN_CODE FROM Fighter WHERE FILE_NO = @FileNo
      )
   )
   BEGIN
      SELECT @ErorMesg = N'هنرجو مورد نظر در "ناحیه ' + REGN_CODE + N' "  می باشد و نمی توانید در درخواستی با ناحیه دیگری ثبت نمایید.'
        FROM Fighter 
       WHERE FILE_NO = @FileNo;
       
      RAISERROR (@ErorMesg, -- Message text.
                 16, -- Severity.
                 1   -- State.
                );
      ROLLBACK TRANSACTION;
   END
   --ELSE IF NOT EXISTS(SELECT * FROM Fighter WHERE FILE_NO = @FileNo AND FGPB_TYPE_DNRM IN ('002', '003')) AND NOT EXISTS(SELECT * FROM Request WHERE RQID = @RqstRqid AND RQTP_CODE IN ('009', '001', '016', '002', '011', '013', '014', '022', '023', '025')) AND NOT EXISTS(SELECT * FROM Member_Ship WHERE FIGH_FILE_NO = @FileNo AND [TYPE] = '001' AND RECT_CODE = '004' AND CAST(END_DATE AS DATE) >= CAST(GETDATE() AS DATE))
   --BEGIN
   --   SELECT @ErorMesg = N' تاریخ اعتبار کارت عضویت هنرجو ' + NAME_DNRM + N' به پایان رسیده. جهت تمدید کارت عضویت اقدام نمایید. '
   --     FROM Fighter 
   --    WHERE FILE_NO = @FileNo;
       
   --   RAISERROR (@ErorMesg, -- Message text.
   --              16, -- Severity.
   --              1   -- State.
   --             );
   --   ROLLBACK TRANSACTION;
   --END
   ELSE IF @MustLock = '002' -- اگر درخواست از نوعی باشد که هنرجو باید قفل شود باید چک کنیم که درگیر فرآیندی دیگری نباشد
      AND  
      EXISTS(
         SELECT * FROM Fighter f
         WHERE f.FILE_NO = @FileNo 
           AND f.FIGH_STAT = '001' -- Lock
           AND f.RQST_RQID <> @RqstRqid
           AND 
           EXISTS(
            SELECT * FROM Request r, Request_Row rr
            WHERE f.RQST_RQID = r.RQID
              AND r.RQST_STAT = '001'
              AND rr.RQST_RQID = r.RQID
              AND rr.RECD_STAT = '002'
           )
      )
      AND 
      -- 1396/03/01
      /* اگر درخواستی پیرو درخواستی که هنرجو در آن قفل باشد بایستی سیستم این کار را انجام دهد */
      NOT EXISTS(
         SELECT *
           FROM dbo.Fighter
          WHERE FILE_NO = @FileNo
            AND RQST_RQID = dbo.GET_NSPR_U('<Request nstptype="001" rqid="' + CAST(@RqstRqid AS VARCHAR(20)) + '"/>')          
      )
   BEGIN
      SELECT @RqstRqid = r.RQID
            ,@RqtpDesc = rt.RQTP_DESC
      FROM Fighter f, Request r, Request_Type rt
      WHERE f.RQST_RQID = r.RQID
        AND r.RQTP_CODE = rt.CODE
        AND f.FILE_NO   = @FileNo;
      SET @ErorMesg = N'هنرجو مورد نظر به شماره پرونده ' + CAST(@FileNo AS VARCHAR) + N' در فرآیند ' + @RqtpDesc + N' به شماره درخواست ' + CAST(@RqstRqid AS VARCHAR) + N' درگیر می باشد';
      RAISERROR (@ErorMesg, -- Message text.
                 16, -- Severity.
                 1   -- State.
                );
      ROLLBACK TRANSACTION;   
   END
   ELSE IF EXISTS(SELECT * FROM Fighter WHERE FILE_NO = @FileNo AND ISNULL(ACTV_TAG_DNRM, '101') <= '100') AND EXISTS(SELECT * FROM Request WHERE RQID = @RqstRqid AND RQTP_CODE NOT IN ('014', '002'))
   BEGIN
      SELECT @ErorMesg = N' هنرجو ' + NAME_DNRM + N' به دلایلی از سیستم به صورت موقت خارج شده لطفا به سرپرستی اطلاع دهید '
        FROM Fighter 
       WHERE FILE_NO = @FileNo;
       
      RAISERROR (@ErorMesg, -- Message text.
                 16, -- Severity.
                 1   -- State.
                );
      ROLLBACK TRANSACTION;
   END

   MERGE dbo.Request_Row T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQST_RQID = S.RQST_RQID AND 
       T.RWNO      = S.RWNO)
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE();
   
   -- 1396/03/01
   IF EXISTS(
         SELECT *
           FROM dbo.Fighter
          WHERE FILE_NO = @FileNo
            AND RQST_RQID IS NULL
            AND FIGH_STAT = '002'
      ) OR
      /* اگر درخواستی پیرو درخواستی که هنرجو در آن قفل باشد بایستی سیستم این کار را انجام دهد */
      NOT EXISTS(
         SELECT *
           FROM dbo.Fighter
          WHERE FILE_NO = @FileNo
            AND RQST_RQID IS NOT NULL
            AND FIGH_STAT = '001'
            AND RQST_RQID = dbo.GET_NSPR_U('<Request nstptype="001" rqid="' + CAST(@RqstRqid AS VARCHAR(20)) + '"/>')          
      )
   BEGIN            
      -- LOCK FIGHTER IF EXISTS IN REQUEST_ROW
      MERGE dbo.Fighter T
      USING (SELECT I.FIGH_FILE_NO, @MustLock As MUST_LOCK, I.RQST_RQID , I.RECD_STAT
               FROM INSERTED I, Request R 
              WHERE I.RQST_RQID    = R.RQID 
                AND R.RQST_STAT    = '001'
                AND I.FIGH_FILE_NO = @FileNo) S
      ON (T.FILE_NO   = S.FIGH_FILE_NO AND
          S.MUST_LOCK = '002')
      WHEN MATCHED THEN
         UPDATE
            SET RQST_RQID = CASE WHEN S.RECD_STAT = '001' THEN NULL ELSE S.RQST_RQID END
               ,FIGH_STAT = CASE WHEN S.RECD_STAT = '001' THEN '002' ELSE '001' END;
   END
   
   GOTO L$NextRow;
   L$EndFetch:
   CLOSE C#AUPD_RQRO;
   DEALLOCATE C#AUPD_RQRO;END
;
GO
ALTER TABLE [dbo].[Request_Row] ADD CONSTRAINT [CK_RQRO_RECD_STAT] CHECK (([RECD_STAT]='002' OR [RECD_STAT]='001'))
GO
ALTER TABLE [dbo].[Request_Row] ADD CONSTRAINT [RQRO_PK] PRIMARY KEY CLUSTERED  ([RQST_RQID], [RWNO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Request_Row] ADD CONSTRAINT [FK_RQRO_FIGH] FOREIGN KEY ([FIGH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO]) ON DELETE SET NULL
GO
ALTER TABLE [dbo].[Request_Row] ADD CONSTRAINT [FK_RQRO_REGN] FOREIGN KEY ([REGN_PRVN_CNTY_CODE], [REGN_PRVN_CODE], [REGN_CODE]) REFERENCES [dbo].[Region] ([PRVN_CNTY_CODE], [PRVN_CODE], [CODE])
GO
ALTER TABLE [dbo].[Request_Row] ADD CONSTRAINT [FK_RQRO_RQST] FOREIGN KEY ([RQST_RQID]) REFERENCES [dbo].[Request] ([RQID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Request_Row] ADD CONSTRAINT [FK_RQRO_RQTP] FOREIGN KEY ([RQTP_CODE]) REFERENCES [dbo].[Request_Type] ([CODE])
GO
ALTER TABLE [dbo].[Request_Row] ADD CONSTRAINT [FK_RQRO_RQTT] FOREIGN KEY ([RQTT_CODE]) REFERENCES [dbo].[Requester_Type] ([CODE])
GO
