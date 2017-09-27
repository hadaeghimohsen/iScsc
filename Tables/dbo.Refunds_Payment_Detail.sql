CREATE TABLE [dbo].[Refunds_Payment_Detail]
(
[FIDC_FDID] [bigint] NULL,
[PYDT_CODE] [bigint] NOT NULL,
[PYDT_EXPN_CODE] [bigint] NULL,
[RFID] [bigint] NOT NULL CONSTRAINT [DF_Refunds_Payment_Detail_RFID] DEFAULT ((0)),
[RFND_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PYDT_PAY_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[PYDT_EXPN_PRIC] [int] NOT NULL,
[PYDT_EXPN_EXTR_PRCT] [int] NOT NULL,
[PYDT_REMN_PRIC] [int] NOT NULL,
[PYDT_QNTY] [smallint] NULL,
[PYDT_DOCM_NUMB] [bigint] NULL,
[PYDT_ISSU_DATE] [datetime] NULL,
[PYDT_RCPT_MTOD] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PYDT_RECV_LETT_NO] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PYDT_RECV_LETT_DATE] [datetime] NULL,
[PYDT_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_RFPD]
   ON  [dbo].[Refunds_Payment_Detail]
   AFTER INSERT
AS 
BEGIN
	
	DECLARE C$AINS_RFPD CURSOR FOR
	   SELECT FIDC_FDID, PYDT_CODE, PYDT_EXPN_CODE, RFID, PYDT_PAY_STAT,
	          PYDT_EXPN_PRIC, PYDT_EXPN_EXTR_PRCT, PYDT_REMN_PRIC,
	          PYDT_QNTY, PYDT_DOCM_NUMB, PYDT_ISSU_DATE, PYDT_RCPT_MTOD,
	          PYDT_RECV_LETT_NO, PYDT_RECV_LETT_DATE, PYDT_DESC
	     FROM INSERTED I;
	
	DECLARE  @FIDC_FDID           [bigint],
	         @PYDT_CODE           [bigint],
	         @PYDT_EXPN_CODE      [bigint],
	         @RFID                [bigint],
	         @RFND_STAT           [varchar](3),
	         @PYDT_PAY_STAT       [varchar](3) ,
	         @PYDT_EXPN_PRIC      [int] ,
	         @PYDT_EXPN_EXTR_PRCT [int],
	         @PYDT_REMN_PRIC      [int] ,
	         @PYDT_QNTY           [smallint] ,
	         @PYDT_DOCM_NUMB      [bigint] ,
	         @PYDT_ISSU_DATE      [datetime] ,
	         @PYDT_RCPT_MTOD      [varchar](3),
	         @PYDT_RECV_LETT_NO   [varchar](15),
	         @PYDT_RECV_LETT_DATE [datetime],
	         @PYDT_DESC           [nvarchar](250);
	
	OPEN C$AINS_RFPD;
	Fetch_C$AINS_RFPD:
	FETCH NEXT FROM C$AINS_RFPD INTO @FIDC_FDID          ,
	                                 @PYDT_CODE          ,
	                                 @PYDT_EXPN_CODE     ,
	                                 @RFID               ,
	                                 --@RFND_STAT          ,
	                                 @PYDT_PAY_STAT      ,
	                                 @PYDT_EXPN_PRIC     ,
	                                 @PYDT_EXPN_EXTR_PRCT,
	                                 @PYDT_REMN_PRIC     ,
	                                 @PYDT_QNTY          ,
	                                 @PYDT_DOCM_NUMB     ,
	                                 @PYDT_ISSU_DATE     ,
	                                 @PYDT_RCPT_MTOD     ,
	                                 @PYDT_RECV_LETT_NO  ,
	                                 @PYDT_RECV_LETT_DATE,
	                                 @PYDT_DESC          ;
	
	
	IF @@FETCH_STATUS <> 0
	   GOTO End_C$AINS_RFPD;
   
   UPDATE dbo.Refunds_Payment_Detail
      SET RFID = dbo.GNRT_NVID_U()
         ,CRET_BY = UPPER(SUSER_NAME())	
         ,CRET_DATE = GETDATE()
    WHERE RFID = @RFID
      AND FIDC_FDID = @FIDC_FDID
      AND PYDT_CODE = @PYDT_CODE;
	
	GOTO Fetch_C$AINS_RFPD;
	End_C$AINS_RFPD:
	CLOSE C$AINS_RFPD;
	DEALLOCATE C$AINS_RFPD;
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
CREATE TRIGGER [dbo].[CG$AUPD_RFPD]
   ON  [dbo].[Refunds_Payment_Detail]
   AFTER UPDATE
AS 
BEGIN
	
	DECLARE C$AUPD_RFPD CURSOR FOR
	   SELECT FIDC_FDID, 
	          PYDT_CODE, 
	          PYDT_EXPN_CODE, 
	          RFID, 
	          PYDT_PAY_STAT,
	          PYDT_EXPN_PRIC, 
	          PYDT_EXPN_EXTR_PRCT, 
	          PYDT_REMN_PRIC,
	          PYDT_QNTY, 
	          PYDT_DOCM_NUMB, 
	          PYDT_ISSU_DATE, 
	          PYDT_RCPT_MTOD,
	          PYDT_RECV_LETT_NO, 
	          PYDT_RECV_LETT_DATE, 
	          PYDT_DESC
	     FROM INSERTED I;
	
	DECLARE  @FIDC_FDID           [bigint],
	         @PYDT_CODE           [bigint],
	         @PYDT_EXPN_CODE      [bigint],
	         @RFID                [bigint],
	         @RFND_STAT           [varchar](3),
	         @PYDT_PAY_STAT       [varchar](3) ,
	         @PYDT_EXPN_PRIC      [int] ,
	         @PYDT_EXPN_EXTR_PRCT [int],
	         @PYDT_REMN_PRIC      [int] ,
	         @PYDT_QNTY           [smallint] ,
	         @PYDT_DOCM_NUMB      [bigint] ,
	         @PYDT_ISSU_DATE      [datetime] ,
	         @PYDT_RCPT_MTOD      [varchar](3),
	         @PYDT_RECV_LETT_NO   [varchar](15),
	         @PYDT_RECV_LETT_DATE [datetime],
	         @PYDT_DESC           [nvarchar](250);
	
	OPEN C$AUPD_RFPD;
	Fetch_C$AUPD_RFPD:
	FETCH NEXT FROM C$AUPD_RFPD INTO @FIDC_FDID          ,
	                                 @PYDT_CODE          ,
	                                 @PYDT_EXPN_CODE     ,
	                                 @RFID               ,
	                                 --@RFND_STAT        ,
	                                 @PYDT_PAY_STAT      ,
	                                 @PYDT_EXPN_PRIC     ,
	                                 @PYDT_EXPN_EXTR_PRCT,
	                                 @PYDT_REMN_PRIC     ,
	                                 @PYDT_QNTY          ,
	                                 @PYDT_DOCM_NUMB     ,
	                                 @PYDT_ISSU_DATE     ,
	                                 @PYDT_RCPT_MTOD     ,
	                                 @PYDT_RECV_LETT_NO  ,
	                                 @PYDT_RECV_LETT_DATE,
	                                 @PYDT_DESC          ;
	
	
	IF @@FETCH_STATUS <> 0
	   GOTO End_C$AUPD_RFPD;
   
   UPDATE dbo.Refunds_Payment_Detail
      SET MDFY_BY = UPPER(SUSER_NAME())	
         ,MDFY_DATE = GETDATE()
    WHERE RFID = @RFID
      AND FIDC_FDID = @FIDC_FDID
      AND PYDT_CODE = @PYDT_CODE
      AND RFND_STAT = CASE PYDT_PAY_STAT WHEN '002' THEN RFND_STAT ELSE '001' END;
	
	GOTO Fetch_C$AUPD_RFPD;
	End_C$AUPD_RFPD:
	CLOSE C$AUPD_RFPD;
	DEALLOCATE C$AUPD_RFPD;
	
	-- بروز رسانی مبلغ قابل استرداد هزینه
	UPDATE dbo.Finance_Document  
	   SET PYMT_PRIC_DNRM = ROUND(ISNULL((
	         SELECT SUM((PYDT_EXPN_PRIC + PYDT_EXPN_EXTR_PRCT + PYDT_REMN_PRIC) * PYDT_QNTY)
	           FROM dbo.Refunds_Payment_Detail
	          WHERE FIDC_FDID = @FIDC_FDID
	            AND RFND_STAT = '002'
	       ),0), -3),
	       GET_PYMT_PRIC_DNRM = (
	         SELECT SUM(AMNT)
	           FROM dbo.Payment_Method Pm
	          WHERE EXISTS (
	            SELECT *
	              FROM dbo.Finance_Document F, dbo.Request_Row Rr, dbo.Request R, dbo.Payment P, dbo.Payment_Method Pm1
	             WHERE f.RQRO_RQST_RQID = rr.RQST_RQID
	               AND f.RQRO_RWNO = rr.RWNO
	               AND rr.RQST_RQID = r.RQID
	               AND r.RQST_RQID = p.RQST_RQID
	               AND p.CASH_CODE = pm1.PYMT_CASH_CODE
	               AND p.RQST_RQID = pm1.PYMT_RQST_RQID
	               AND pm1.PYMT_CASH_CODE = pm.PYMT_CASH_CODE
	               AND pm1.PYMT_RQST_RQID = pm.PYMT_RQST_RQID
	               AND F.FDID = @FIDC_FDID
	          )	          
	       )	      
	 WHERE FDID = @FIDC_FDID;
END
GO
ALTER TABLE [dbo].[Refunds_Payment_Detail] ADD CONSTRAINT [PK_RFPD] PRIMARY KEY CLUSTERED  ([RFID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Refunds_Payment_Detail] ADD CONSTRAINT [FK_RFPD_EXPN] FOREIGN KEY ([PYDT_EXPN_CODE]) REFERENCES [dbo].[Expense] ([CODE])
GO
ALTER TABLE [dbo].[Refunds_Payment_Detail] ADD CONSTRAINT [FK_RFPD_FIDC] FOREIGN KEY ([FIDC_FDID]) REFERENCES [dbo].[Finance_Document] ([FDID])
GO
ALTER TABLE [dbo].[Refunds_Payment_Detail] ADD CONSTRAINT [FK_RFPD_PYDT] FOREIGN KEY ([PYDT_CODE]) REFERENCES [dbo].[Payment_Detail] ([CODE])
GO
