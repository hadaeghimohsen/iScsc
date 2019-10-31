CREATE TABLE [dbo].[Member_Ship]
(
[RQRO_RQST_RQID] [bigint] NULL,
[RQRO_RWNO] [smallint] NULL,
[FIGH_FILE_NO] [bigint] NOT NULL,
[RWNO] [smallint] NOT NULL CONSTRAINT [DF_MBSP_RWNO] DEFAULT ((0)),
[RECT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[FGPB_RWNO_DNRM] [int] NULL,
[FGPB_RECT_CODE_DNRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STRT_DATE] [datetime] NULL,
[END_DATE] [datetime] NULL,
[NUMB_OF_MONT_DNRM] [int] NULL,
[NUMB_OF_DAYS_DNRM] [int] NULL,
[NUMB_MONT_OFER] [int] NULL CONSTRAINT [DF_Member_Ship_NUMB_MONT_OFER] DEFAULT ((0)),
[NUMB_OF_ATTN_MONT] [int] NULL CONSTRAINT [DF_Member_Ship_NUMB_OF_ATTN_MONT] DEFAULT ((13)),
[NUMB_OF_ATTN_WEEK] [int] NULL CONSTRAINT [DF_Member_Ship_NUMB_OF_ATTN_WEEK] DEFAULT ((3)),
[SUM_ATTN_MONT_DNRM] [int] NULL CONSTRAINT [DF_Member_Ship_REMN_ATTN_MONT_DNRM] DEFAULT ((0)),
[SUM_ATTN_WEEK_DNRM] [int] NULL CONSTRAINT [DF_Member_Ship_REMN_ATTN_WEEK_DNRM] DEFAULT ((0)),
[ATTN_DAY_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Member_Ship_ATTN_DAY_TYPE] DEFAULT ('001'),
[PRNT_CONT] [smallint] NULL,
[SESN_MEET_DATE] [datetime] NULL,
[SESN_MEET_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SMS_SEND] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[VALD_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NEW_FNGR_PRNT] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$ADEL_MBSP]
   ON  [dbo].[Member_Ship]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   /*IF SUSER_NAME() <> 'SCSC' 
   BEGIN
      RAISERROR ('شما مجوز حذف فیزیکی اطلاعات رکورد جدول مورد نظر را ندارید. >:(', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRANSACTION;
   END*/
   
   -- UPDATE FIGHTER TABLE
   IF NOT EXISTS(SELECT * FROM Fighter F, Deleted D
                  WHERE F.FILE_NO = D.FIGH_FILE_NO 
                    AND F.MBSP_RWNO_DNRM = D.RWNO
                    AND D.RECT_CODE = '004')
      RETURN;
   
   DECLARE C#ADEL_MBSP CURSOR FOR
   SELECT DISTINCT FIGH_FILE_NO
   FROM DELETED D;
   
   DECLARE @FILENO BIGINT;
   OPEN C#ADEL_MBSP;
   L$NextRow:
   FETCH NEXT FROM C#ADEL_MBSP INTO @FILENO;
   
   -- Fetch Next Row Is Failed
   IF @@FETCH_STATUS <> 0
      GOTO L$EndFetch;

   -- اگر ردیف فعالی برای کارت عضویت برای این شماره پرونده یافت نشد مقدار دینرمال باید درجدول اصلی خالی شود
   IF NOT EXISTS(
      SELECT 
            C.FIGH_FILE_NO, 
            C.RWNO
        FROM dbo.Member_Ship C, Deleted D
       WHERE C.FIGH_FILE_NO = D.FIGH_FILE_NO AND
             C.FIGH_FILE_NO = @FILENO        AND
             C.RECT_CODE    = D.RECT_CODE    AND
             C.RECT_CODE    = '004'          AND
             C.RWNO  NOT IN (SELECT D.RWNO FROM Deleted D WHERE C.FIGH_FILE_NO = D.FIGH_FILE_NO)
   )
   BEGIN
      UPDATE DBO.Fighter
         SET MBSP_RWNO_DNRM = NULL
       WHERE FILE_NO = @FILENO;
       GOTO L$NextRow;
   END    
      
   MERGE dbo.Fighter T
   USING (SELECT TOP 1 
            C.FIGH_FILE_NO, 
            C.RWNO
            FROM dbo.Member_Ship C, Deleted D
           WHERE C.FIGH_FILE_NO = D.FIGH_FILE_NO AND
                 C.FIGH_FILE_NO = @FILENO        AND
                 C.RECT_CODE    = D.RECT_CODE    AND
                 C.RECT_CODE    = '004'          AND
                 C.RWNO  NOT IN (SELECT D.RWNO FROM Deleted D WHERE C.FIGH_FILE_NO = D.FIGH_FILE_NO)
           ORDER BY C.RWNO DESC) S
   ON (T.FILE_NO   = S.FIGH_FILE_NO)
   WHEN MATCHED THEN
      UPDATE 
         SET MBSP_RWNO_DNRM = S.RWNO;            

   GOTO L$NextRow;
   L$EndFetch:
   CLOSE C#ADEL_MBSP;
   DEALLOCATE C#ADEL_MBSP;   
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AINS_MBSP]
   ON  [dbo].[Member_Ship]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Member_Ship T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQRO_RQST_RQID = S.RQRO_RQST_RQID AND
       T.RQRO_RWNO      = S.RQRO_RWNO      AND
       T.FIGH_FILE_NO   = S.FIGH_FILE_NO   AND
       T.RECT_CODE      = S.RECT_CODE)
   WHEN MATCHED THEN
      UPDATE
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,RWNO      = (SELECT ISNULL(MAX(RWNO),0) + 1 FROM MEMBER_SHIP WHERE FIGH_FILE_NO = S.FIGH_FILE_NO AND RECT_CODE = S.RECT_CODE/*RQRO_RQST_RQID < S.RQRO_RQST_RQID*/)
            ,VALD_TYPE = '002';

END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_MBSP]
   ON  [dbo].[Member_Ship]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   -- Insert statements for trigger here
   MERGE dbo.Member_Ship T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQRO_RQST_RQID = S.RQRO_RQST_RQID AND
       T.RQRO_RWNO      = S.RQRO_RWNO      AND
       T.FIGH_FILE_NO   = S.FIGH_FILE_NO   AND
       T.RWNO           = S.RWNO           AND
       T.RECT_CODE      = S.RECT_CODE)
   WHEN MATCHED THEN
      UPDATE
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE()
            ,NUMB_OF_MONT_DNRM = CASE 
                                    WHEN DATEDIFF(DAY, S.STRT_DATE, S.END_DATE) < 30 THEN 1
                                    ELSE DATEDIFF(MONTH, S.STRT_DATE, S.END_DATE) 
                                 END
            ,NUMB_OF_DAYS_DNRM = DATEDIFF(DAY, S.STRT_DATE, S.END_DATE) + 1
            /*,CHCK_TOTL_MONT_DNRM = CASE 
                                      WHEN DATEDIFF(MONTH, S.STRT_DATE, S.END_DATE) = 
                                           DATEDIFF(DAY, S.STRT_DATE, S.END_DATE) % 30 AND
                                           DATEDIFF(MONTH, S.STRT_DATE, S.END_DATE) > 0
                                      THEN '002'
                                      ELSE '001'
                                    END*/;
   
   -- چک میکنیم که اگر تعداد ماه های تخفیف بیشتر از تعداد ماه های بازه باشد جلو آن را بگیریم
   IF EXISTS (
      SELECT *
        FROM Member_Ship M, INSERTED I
       WHERE M.RQRO_RQST_RQID = I.RQRO_RQST_RQID
         AND M.RQRO_RWNO = I.RQRO_RWNO
         AND M.RECT_CODE = I.RECT_CODE
         AND M.NUMB_OF_MONT_DNRM < I.NUMB_MONT_OFER
   )
   BEGIN
      RAISERROR (N'تعداد ماه های تخفیف نمی تواند از تعداد کل ماه بیشتر باشد', 16, 1);
      RETURN;
   END;
   
   /*
	TYPE : 
		001 - اعتبار عادی 
		002 - اعتبار مربوط به عضویت سبک
		003 - جلسه خصوصی با مربی
		004 - قرارداد پرسنل
		005 - بلاک کردن یا فریز کردن زمان حضور
		006 - جلسه مشاوره حضوری یا تلفنی
   */
   
   -- UPDATE FIGHTER TABLE
   MERGE dbo.Fighter T
   USING (SELECT * FROM INSERTED I 
           WHERE I.RWNO = (SELECT MAX(RWNO) FROM MEMBER_SHIP M 
                            WHERE M.FIGH_FILE_NO = I.FIGH_FILE_NO AND 
                                  M.TYPE IN ( '001', '004' ) AND
								          M.VALD_TYPE = '002' AND
                                  M.RECT_CODE    = '004')) S
   ON (T.FILE_NO   = S.FIGH_FILE_NO AND
       S.TYPE IN ('001', '004') AND
	    S.VALD_TYPE = '002' AND 
       S.RECT_CODE = '004')
   WHEN MATCHED THEN
      UPDATE 
         SET MBSP_RWNO_DNRM = S.RWNO
            ,MBSP_END_DATE = S.End_Date
            ,MBSP_STRT_DATE = S.Strt_Date;
   
   -- رکورد مربوط به جلسه خصوصی با مربی
   MERGE dbo.Fighter T
   USING (SELECT * FROM INSERTED I 
           WHERE I.RWNO = (SELECT MAX(RWNO) FROM MEMBER_SHIP M 
                            WHERE M.FIGH_FILE_NO = I.FIGH_FILE_NO AND 
                                  M.TYPE = '003' AND
								          m.VALD_TYPE = '002' AND 
                                  M.RECT_CODE    = '004')) S
   ON (T.FILE_NO   = S.FIGH_FILE_NO AND
       S.TYPE = '003' AND
	    S.VALD_TYPE = '002' AND 
       S.RECT_CODE = '004')
   WHEN MATCHED THEN
      UPDATE 
         SET MBCO_RWNO_DNRM = S.RWNO;
   
   -- رکورد مربوط به بلوکه کردن تاریخ حضور
   MERGE dbo.Fighter T
   USING (SELECT * FROM INSERTED I 
           WHERE I.RWNO = (SELECT MAX(RWNO) FROM MEMBER_SHIP M 
                            WHERE M.FIGH_FILE_NO = I.FIGH_FILE_NO AND 
                                  M.TYPE = '005' AND
								          m.VALD_TYPE = '002' AND 
                                  M.RECT_CODE    = '004')) S
   ON (T.FILE_NO   = S.FIGH_FILE_NO AND
       S.TYPE = '005' AND
	    s.VALD_TYPE = '002' AND 
       S.RECT_CODE = '004')
 WHEN MATCHED THEN
      UPDATE 
         SET MBFZ_RWNO_DNRM = S.RWNO;
   
   -- رکورد مربوط به جلسه مشاوره
   MERGE dbo.Fighter T
   USING (SELECT * FROM INSERTED I 
           WHERE I.RWNO = (SELECT MAX(RWNO) FROM MEMBER_SHIP M 
                            WHERE M.FIGH_FILE_NO = I.FIGH_FILE_NO AND 
                                  M.TYPE = '006' AND
								          m.VALD_TYPE = '002' AND 
                                  M.RECT_CODE    = '004')) S
   ON (T.FILE_NO   = S.FIGH_FILE_NO AND
       S.TYPE = '006' AND
	    s.VALD_TYPE = '002' AND 
       S.RECT_CODE = '004')
   WHEN MATCHED THEN
      UPDATE 
         SET MBSM_RWNO_DNRM = S.RWNO;
   
   -- اگر تعداد ردیف ها بیشتر باشد نیازی به چک کردن پیامک ندارد
   IF ((SELECT COUNT(*) FROM Inserted WHERE Inserted.RECT_CODE = '004') > 1) RETURN;
   
   -- 1396/10/05 * ثبت پیامک       
   DECLARE @CellPhon VARCHAR(11)
          ,@ChatId BIGINT
          ,@DadCellPhon VARCHAR(11)
          ,@DadChatId BIGINT
          ,@MomCellPhon VARCHAR(11)
          ,@MomChatId BIGINT
          ,@SexType VARCHAR(3)
          ,@FrstName NVARCHAR(250)
          ,@LastName NVARCHAR(250)
          ,@FileNo BIGINT
          ,@NumbOfAttnMont INT
          ,@SumOfAttnMont INT
          ,@EndDate DATE;
          
   SELECT @CellPhon = f.CELL_PHON_DNRM
         ,@ChatId = F.CHAT_ID_DNRM
         ,@DadCellPhon = f.DAD_CELL_PHON_DNRM
         ,@DadChatId = f.DAD_CHAT_ID_DNRM
         ,@MomCellPhon = f.MOM_CELL_PHON_DNRM
         ,@MomChatId = f.MOM_CHAT_ID_DNRM
         ,@SexType = f.SEX_TYPE_DNRM
         ,@FrstName = f.FRST_NAME_DNRM
         ,@LastName = f.LAST_NAME_DNRM
         ,@FileNo = f.FILE_NO
         ,@EndDate = i.END_DATE
         ,@NumbOfAttnMont = i.NUMB_OF_ATTN_MONT
         ,@SumOfAttnMont = i.SUM_ATTN_MONT_DNRM
     FROM dbo.Fighter f, Inserted i
    WHERE f.FILE_NO = i.FIGH_FILE_NO
      AND i.RECT_CODE = '004';
          
   IF (
         (@CellPhon IS NOT NULL AND LEN(@CellPhon) != 0)  OR 
         (@DadCellPhon IS NOT NULL AND LEN(@DadCellPhon) != 0) OR
         (@MomCellPhon IS NOT NULL AND LEN(@MomCellPhon) != 0)
      ) AND
      (
         DATEDIFF(DAY, GETDATE(), @EndDate) <= (SELECT MIN_NUMB_DAY_RMND FROM dbo.Message_Broadcast WHERE MSGB_TYPE = '009' AND ISNULL(MIN_NUMB_DAY_RMND, 0) != 0) OR
         (@NumbOfAttnMont > 0 AND ABS(@NumbOfAttnMont - @SumOfAttnMont) <= (SELECT MIN_NUMB_ATTN_RMND FROM dbo.Message_Broadcast WHERE MSGB_TYPE = '009' AND ISNULL(MIN_NUMB_ATTN_RMND, 0) != 0)) 
      )
   BEGIN
      DECLARE @MsgbStat VARCHAR(3)
             ,@MsgbText NVARCHAR(MAX)
             ,@ClubName NVARCHAR(250)
             ,@InsrCnamStat VARCHAR(3)
             ,@InsrFnamStat VARCHAR(3);
             
      SELECT @MsgbStat = STAT
            ,@MsgbText = MSGB_TEXT
            ,@ClubName = CLUB_NAME
            ,@InsrCnamStat = INSR_CNAM_STAT
            ,@InsrFnamStat = INSR_FNAM_STAT
        FROM dbo.Message_Broadcast
       WHERE MSGB_TYPE = '009';
      
      IF @MsgbStat = '002' 
      BEGIN
         IF @InsrFnamStat = '002'
            SET @MsgbText = (SELECT DOMN_DESC FROM dbo.[D$SXDC] WHERE VALU = @SexType) + N' ' + @FrstName + N' ' + @LastName + N' ' + @MsgbText;
         
         IF @InsrCnamStat = '002'
            SET @MsgbText = @MsgbText + N' ' + @ClubName;
            
         DECLARE @XMsg XML;
         SELECT @XMsg = (
            SELECT 5 AS '@subsys',
                   '001' AS '@linetype',
                   (
                     SELECT @CellPhon AS '@phonnumb',
                            (
                                SELECT '009' AS '@type' 
                                       ,@MsgbText
                                   FOR XML PATH('Message'), TYPE 
                            ) 
                        FOR XML PATH('Contact'), TYPE
                   ),
                   (
                     SELECT @DadCellPhon AS '@phonnumb',
                            (
                           SELECT '009' AS '@type' 
                                       ,@MsgbText
                                   FOR XML PATH('Message'), TYPE 
                            ) 
                        FOR XML PATH('Contact'), TYPE
                   ),
                   (
                     SELECT @MomCellPhon AS '@phonnumb',
                            (
                                SELECT '009' AS '@type' 
                                       ,@MsgbText
                                   FOR XML PATH('Message'), TYPE 
                            ) 
                        FOR XML PATH('Contact'), TYPE
                   )
              FOR XML PATH('Contacts'), ROOT('Process')                            
         );
         EXEC dbo.MSG_SEND_P @X = @XMsg -- xml
      END;
   END;
   
   IF EXISTS(SELECT * FROM dbo.Message_Broadcast WHERE MSGB_TYPE = '019' AND STAT = '002') AND 
      EXISTS(SELECT * FROM Inserted i , Deleted d WHERE i.RQRO_RQST_RQID = d.RQRO_RQST_RQID AND i.FIGH_FILE_NO = d.FIGH_FILE_NO AND i.RECT_CODE = d.RECT_CODE AND i.RWNO = d.RWNO AND i.RECT_CODE = '004' AND i.VALD_TYPE != d.VALD_TYPE)
   BEGIN
      DECLARE @LineType VARCHAR(3)
             ,@Cel1Phon VARCHAR(11)
             ,@Cel2Phon VARCHAR(11)
             ,@Cel3Phon VARCHAR(11)
             ,@Cel4Phon VARCHAR(11)
             ,@Cel5Phon VARCHAR(11)
             ,@AmntType VARCHAR(3)
             ,@AmntTypeDesc NVARCHAR(255);
             
      SELECT @MsgbStat = STAT
            ,@MsgbText = MSGB_TEXT
            ,@LineType = LINE_TYPE
            ,@Cel1Phon = CEL1_PHON
            ,@Cel2Phon = CEL2_PHON
            ,@Cel3Phon = CEL3_PHON
            ,@Cel4Phon = CEL4_PHON
            ,@Cel5Phon = CEL5_PHON            
        FROM dbo.Message_Broadcast
       WHERE MSGB_TYPE = '019';
      
      SELECT @AmntType = rg.AMNT_TYPE, 
             @AmntTypeDesc = d.DOMN_DESC
        FROM iScsc.dbo.Regulation rg, iScsc.dbo.[D$ATYP] d
       WHERE rg.TYPE = '001'
         AND rg.REGL_STAT = '002'
         AND rg.AMNT_TYPE = d.VALU;
      
      SELECT @MsgbText = (
         SELECT CASE i.VALD_TYPE WHEN '001' THEN N'غیر فعال کردن دوره' WHEN '002' THEN N'فعال کردن دوره' END + CHAR(10) +
                rt.RQTP_DESC + CHAR(10) + 
                N'تاریخ تایید درخواست ' + dbo.GET_MTST_U(r.SAVE_DATE) + CHAR(10) +
                N'نام مشترک ' + f.NAME_DNRM + CHAR(10) + 
                N'کاربر : ' + UPPER(SUSER_NAME()) + CHAR(10) + 
                N'تاریخ : ' + dbo.GET_MTST_U(GETDATE())
           FROM Deleted d,
                Inserted i,
                dbo.Request_Type rt,
                dbo.Request r,
                dbo.Request_Row rr,
                dbo.Fighter f
          WHERE d.RQRO_RQST_RQID = i.RQRO_RQST_RQID
            AND d.FIGH_FILE_NO = i.FIGH_FILE_NO
            AND d.RECT_CODE = i.RECT_CODE
            AND d.RWNO = i.RWNO
            AND d.RECT_CODE = '004'
            AND r.RQTP_CODE = rt.CODE
            AND r.RQID = rr.RQST_RQID
            AND rr.FIGH_FILE_NO = f.FILE_NO
      );          
      
      IF @MsgbStat = '002' 
      BEGIN      
         SELECT @XMsg = (
            SELECT 5 AS '@subsys',
                   @LineType AS '@linetype',
                   (
                     SELECT @Cel1Phon AS '@phonnumb',
                            (
                                SELECT '019' AS '@type' 
                                       ,@MsgbText
                                   FOR XML PATH('Message'), TYPE 
                            ) 
                        FOR XML PATH('Contact'), TYPE
                   ),
                   (
                     SELECT @Cel2Phon AS '@phonnumb',
                            (
                                SELECT '019' AS '@type' 
                                       ,@MsgbText
                                   FOR XML PATH('Message'), TYPE 
                            ) 
                        FOR XML PATH('Contact'), TYPE
                   ),
                   (
                     SELECT @Cel3Phon AS '@phonnumb',
                            (
                                SELECT '019' AS '@type' 
                                       ,@MsgbText
                                   FOR XML PATH('Message'), TYPE 
                            ) 
                        FOR XML PATH('Contact'), TYPE
                   ),
                   (
                     SELECT @Cel4Phon AS '@phonnumb',
                            (
                                SELECT '019' AS '@type' 
                                       ,@MsgbText
                                   FOR XML PATH('Message'), TYPE 
                            ) 
                        FOR XML PATH('Contact'), TYPE
                   ),
                   (
                     SELECT @Cel5Phon AS '@phonnumb',
                            (
                                SELECT '019' AS '@type' 
                                       ,@MsgbText
                                   FOR XML PATH('Message'), TYPE 
                            ) 
                        FOR XML PATH('Contact'), TYPE
                   )                   
              FOR XML PATH('Contacts'), ROOT('Process')                            
         );
         EXEC dbo.MSG_SEND_P @X = @XMsg -- xml                  
      END;
   END 
   
   -- 1396/11/15 * ثبت پیامک تلگرام
   IF (
         @ChatId IS NOT NULL OR
         @DadChatId IS NOT NULL OR
         @MomChatId IS NOT NULL
      ) AND 
      (
         DATEDIFF(DAY, GETDATE(), @EndDate) <= (SELECT MIN_NUMB_DAY_RMND FROM dbo.Message_Broadcast WHERE MSGB_TYPE = '009' AND ISNULL(MIN_NUMB_DAY_RMND, 0) != 0) OR
         (@NumbOfAttnMont - @SumOfAttnMont) <= (SELECT MIN_NUMB_ATTN_RMND FROM dbo.Message_Broadcast WHERE MSGB_TYPE = '009' AND ISNULL(MIN_NUMB_ATTN_RMND, 0) != 0) 
      )
   BEGIN  
      DECLARE @TelgStat VARCHAR(3);
      
      SELECT @TelgStat = TELG_STAT
            ,@MsgbText = MSGB_TEXT
            ,@ClubName = CLUB_NAME
            ,@InsrCnamStat = INSR_CNAM_STAT
            ,@InsrFnamStat = INSR_FNAM_STAT
        FROM dbo.Message_Broadcast
       WHERE MSGB_TYPE = '009';
      
      IF @TelgStat = '002'
      BEGIN
         IF @InsrFnamStat = '002'
            SET @MsgbText = (SELECT DOMN_DESC FROM dbo.[D$SXDC] WHERE VALU = @SexType) + N' ' + @FrstName + N' ' + @LastName + N' ' + CHAR(10) + @MsgbText ;--+ ISNULL(@MsgbText, N'');
         
         IF @InsrCnamStat = '002'
            SET @MsgbText = ISNULL(@MsgbText, N'') + N' ' + @ClubName;
         
         IF EXISTS (SELECT name FROM sys.databases WHERE name = N'iRoboTech')
         BEGIN
            DECLARE @RoboServFileNo BIGINT;
            SELECT @RoboServFileNo = SERV_FILE_NO
              FROM iRoboTech.dbo.Service_Robot
             WHERE ROBO_RBID = 391
               AND CHAT_ID = @ChatId;
            
            IF @RoboServFileNo IS NOT NULL
               EXEC iRoboTech.dbo.INS_SRRM_P @SRBT_SERV_FILE_NO = @RoboServFileNo, -- bigint
                   @SRBT_ROBO_RBID = 391, -- bigint
                   @RWNO = 0, -- bigint
                   @SRMG_RWNO = NULL, -- bigint
                   @Ordt_Ordr_Code = NULL, -- bigint
                   @Ordt_Rwno = NULL, -- bigint
                   @MESG_TEXT = @MsgbText, -- nvarchar(max)
                   @FILE_ID = NULL, -- varchar(200)
                   @FILE_PATH = NULL, -- nvarchar(max)
                   @MESG_TYPE = '001', -- varchar(3)
                   @LAT = NULL, -- float
                   @LON = NULL, -- float
                   @CONT_CELL_PHON = NULL; -- varchar(11)
            
            SET @RoboServFileNo = NULL;            
            SELECT @RoboServFileNo = SERV_FILE_NO
              FROM iRoboTech.dbo.Service_Robot
             WHERE ROBO_RBID = 391
               AND CHAT_ID = @DadChatId;
            
            IF @RoboServFileNo IS NOT NULL
               EXEC iRoboTech.dbo.INS_SRRM_P @SRBT_SERV_FILE_NO = @RoboServFileNo, -- bigint
                   @SRBT_ROBO_RBID = 391, -- bigint
                   @RWNO = 0, -- bigint
                   @SRMG_RWNO = NULL, -- bigint
                   @Ordt_Ordr_Code = NULL, -- bigint
                   @Ordt_Rwno = NULL, -- bigint
                   @MESG_TEXT = @MsgbText, -- nvarchar(max)
                   @FILE_ID = NULL, -- varchar(200)
                   @FILE_PATH = NULL, -- nvarchar(max)
                   @MESG_TYPE = '001', -- varchar(3)
                   @LAT = NULL, -- float
                   @LON = NULL, -- float
                   @CONT_CELL_PHON = NULL; -- varchar(11)
            
            SET @RoboServFileNo = NULL;
            SELECT @RoboServFileNo = SERV_FILE_NO
              FROM iRoboTech.dbo.Service_Robot
             WHERE ROBO_RBID = 391
               AND CHAT_ID = @MomChatId;
            
            IF @RoboServFileNo IS NOT NULL
               EXEC iRoboTech.dbo.INS_SRRM_P @SRBT_SERV_FILE_NO = @RoboServFileNo, -- bigint
                   @SRBT_ROBO_RBID = 391, -- bigint
                   @RWNO = 0, -- bigint
                   @SRMG_RWNO = NULL, -- bigint
                   @Ordt_Ordr_Code = NULL, -- bigint
                   @Ordt_Rwno = NULL, -- bigint
                   @MESG_TEXT = @MsgbText, -- nvarchar(max)
                   @FILE_ID = NULL, -- varchar(200)
                   @FILE_PATH = NULL, -- nvarchar(max)
                   @MESG_TYPE = '001', -- varchar(3)
                   @LAT = NULL, -- float
                   @LON = NULL, -- float
                   @CONT_CELL_PHON = NULL; -- varchar(11)            
         END;
      END;
   END;         
END;
GO
ALTER TABLE [dbo].[Member_Ship] ADD CONSTRAINT [CK_MBSP_RECT_CODE] CHECK (([RECT_CODE]='004' OR [RECT_CODE]='003' OR [RECT_CODE]='002' OR [RECT_CODE]='001'))
GO
ALTER TABLE [dbo].[Member_Ship] ADD CONSTRAINT [CK_MBSP_STRT_DATE] CHECK (([STRT_DATE]<=[END_DATE]))
GO
ALTER TABLE [dbo].[Member_Ship] ADD CONSTRAINT [CK_MBSP_END_DATE] CHECK (([STRT_DATE]<=[END_DATE]))
GO
ALTER TABLE [dbo].[Member_Ship] ADD CONSTRAINT [MBSP_PK] PRIMARY KEY CLUSTERED  ([FIGH_FILE_NO], [RWNO], [RECT_CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Member_Ship] ADD CONSTRAINT [UK_MBSP] UNIQUE NONCLUSTERED  ([FIGH_FILE_NO], [RECT_CODE], [RWNO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Member_Ship] ADD CONSTRAINT [FK_MBSP_FGPB] FOREIGN KEY ([FIGH_FILE_NO], [FGPB_RWNO_DNRM], [FGPB_RECT_CODE_DNRM]) REFERENCES [dbo].[Fighter_Public] ([FIGH_FILE_NO], [RWNO], [RECT_CODE])
GO
ALTER TABLE [dbo].[Member_Ship] ADD CONSTRAINT [FK_MBSP_FIGH] FOREIGN KEY ([FIGH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Member_Ship] ADD CONSTRAINT [FK_MBSP_RQRO] FOREIGN KEY ([RQRO_RQST_RQID], [RQRO_RWNO]) REFERENCES [dbo].[Request_Row] ([RQST_RQID], [RWNO]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'Short_Name', N'MBSP', 'SCHEMA', N'dbo', 'TABLE', N'Member_Ship', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد ماه های تخفیف', 'SCHEMA', N'dbo', 'TABLE', N'Member_Ship', 'COLUMN', N'NUMB_MONT_OFER'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد روز دوره', 'SCHEMA', N'dbo', 'TABLE', N'Member_Ship', 'COLUMN', N'NUMB_OF_DAYS_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'محاسبه تعداد ماه های بازه تاریخی شروع و پایان', 'SCHEMA', N'dbo', 'TABLE', N'Member_Ship', 'COLUMN', N'NUMB_OF_MONT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'زمان و تاریخ برای جلسه مشاوره', 'SCHEMA', N'dbo', 'TABLE', N'Member_Ship', 'COLUMN', N'SESN_MEET_DATE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت برگذاری جلسه مشاوره', 'SCHEMA', N'dbo', 'TABLE', N'Member_Ship', 'COLUMN', N'SESN_MEET_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ارسال پیامک انجام شود ', 'SCHEMA', N'dbo', 'TABLE', N'Member_Ship', 'COLUMN', N'SMS_SEND'
GO
EXEC sp_addextendedproperty N'MS_Description', N'آیا دوره معتبر است؟', 'SCHEMA', N'dbo', 'TABLE', N'Member_Ship', 'COLUMN', N'VALD_TYPE'
GO
