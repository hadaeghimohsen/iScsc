SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CRET_STIS_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	BEGIN TRY
	BEGIN TRANSACTION [T$CRET_STIS_P]
	
	-- Check Validation For Access Run Procedure Privilge
	DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>252</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 252 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
	
	-- Params 
	DECLARE @FromDate DATE = @x.query('.').value('(Statistic/@fromdate)[1]', 'DATE'),
	        @ToDate DATE = @x.query('.').value('(Statistic/@todate)[1]', 'DATE');
	
	-- Local Var
	DECLARE @StisDate DATE = @FromDate,
	        @StisCode BIGINT,
	        @Rqid BIGINT,
	        @RefCode BIGINT,
	        @SexType VARCHAR(3),
	        @StisDesc NVARCHAR(250),
	        @SumExpnAmnt BIGINT,
	        @SumDsctAmnt BIGINT,
	        @SumRemnAmnt BIGINT,
	        @SumCashAmnt BIGINT,
	        @SumPosAmnt BIGINT,
	        @SumC2CAmnt BIGINT,
	        @SumDpstAmnt BIGINT;
	
	-- به تعداد بازه تاریخی باید عملیات ایجاد آمار را اجرا کنیم
	WHILE @StisDate <= @ToDate
	BEGIN
	   IF EXISTS (SELECT * FROM dbo.Statistic s WHERE CAST(s.STIS_DATE AS DATE) = @StisDate)
	   BEGIN 
	      GOTO L$NextDate;
	   END
	   
      INSERT INTO dbo.Statistic ( CODE ,STIS_DATE ,STIS_STAT )
      VALUES  ( 0 , @StisDate , '001' );
      SELECT @StisCode = s.CODE
        FROM dbo.Statistic s
       WHERE CAST(s.STIS_DATE AS DATE) = @StisDate
         AND s.STIS_STAT = '001'
         AND s.CRET_BY = UPPER(SUSER_NAME());
      
      -- 7th * Summery
	   INSERT INTO dbo.Statistic_Detail ( STIS_CODE ,CODE ,STIS_DESC )
	   VALUES  ( @StisCode ,dbo.GNRT_NVID_U() ,N'***** گزارش درآمدها *****' );
      
      -- 7th * Summery
	   --INSERT INTO dbo.Statistic_Detail ( STIS_CODE ,CODE )
	   --VALUES  ( @StisCode ,dbo.GNRT_NVID_U() );
         
	   -- 1st * بررسی درخواست های دوره ای
	   DECLARE C$Rqst CURSOR FOR
	      SELECT r.RQID, f.SEX_TYPE_DNRM, m.MTOD_DESC, p.SUM_EXPN_PRIC, 
	             p.SUM_PYMT_DSCN_DNRM, (p.SUM_EXPN_PRIC - (p.SUM_RCPT_EXPN_PRIC + p.SUM_PYMT_DSCN_DNRM)) AS SUM_REMN_DNRM
	        FROM dbo.Request r, dbo.Request_Row rr, dbo.Fighter f, 
	             dbo.Payment p, dbo.Payment_Detail pd, dbo.Method m
	       WHERE r.RQID = rr.RQST_RQID
	         AND rr.FIGH_FILE_NO = f.FILE_NO
	         AND r.RQID = p.RQST_RQID
	         AND p.RQST_RQID = pd.PYMT_RQST_RQID
	         AND pd.MTOD_CODE_DNRM = m.CODE
	         AND r.RQTP_CODE IN ('001', '009')
	         AND r.RQST_STAT = '002'
	         AND f.ACTV_TAG_DNRM >= '101'
	         AND CAST(r.SAVE_DATE AS DATE) = @StisDate;
	   
	   OPEN [C$Rqst];
	   L$Loop1:
	   FETCH [C$Rqst] INTO @Rqid, @SexType, @StisDesc, @SumExpnAmnt, @SumDsctAmnt, @SumRemnAmnt
	   
	   IF @@FETCH_STATUS <> 0
	      GOTO L$EndLoop1;
	   
	   MERGE dbo.Statistic_Detail T
	   USING (SELECT @StisCode AS STIS_CODE, 
	                 @StisDesc AS STIS_DESC, 
	                 @SexType AS SEX_TYPE,
	                 @SumExpnAmnt AS SUM_EXPN_AMNT,
	                 @SumDsctAmnt AS SUM_DSCT_AMNT,
	                 @SumRemnAmnt AS SUM_REMN_AMNT,
	                 ISNULL((SELECT SUM(pm.AMNT) FROM dbo.Payment_Method pm WHERE pm.RQRO_RQST_RQID = @Rqid AND pm.RCPT_MTOD = '001'), 0) AS SUM_CASH_AMNT,
	                 ISNULL((SELECT SUM(pm.AMNT) FROM dbo.Payment_Method pm WHERE pm.RQRO_RQST_RQID = @Rqid AND pm.RCPT_MTOD = '003'), 0) AS SUM_POS_AMNT,
	                 ISNULL((SELECT SUM(pm.AMNT) FROM dbo.Payment_Method pm WHERE pm.RQRO_RQST_RQID = @Rqid AND pm.RCPT_MTOD = '005'), 0) AS SUM_DPST_AMNT,
	                 ISNULL((SELECT SUM(pm.AMNT) FROM dbo.Payment_Method pm WHERE pm.RQRO_RQST_RQID = @Rqid AND pm.RCPT_MTOD = '009'), 0) AS SUM_C2C_AMNT) S
	   ON (T.STIS_CODE = S.STIS_CODE AND 
	       T.STIS_DESC = S.STIS_DESC AND 
	       T.SEX_TYPE = S.SEX_TYPE)
	   WHEN NOT MATCHED THEN 
	      INSERT ( STIS_CODE, CODE, STIS_DESC, SEX_TYPE, CONT_NUMB, SUM_EXPN_AMNT, SUM_DSCT_AMNT, SUM_REMN_AMNT, SUM_CASH_AMNT, SUM_POS_AMNT, SUM_C2C_AMNT, SUM_DPST_AMNT, AMNT_TYPE )
	      VALUES ( s.STIS_CODE, dbo.GNRT_NVID_U(), S.STIS_DESC, S.SEX_TYPE, 1, S.SUM_EXPN_AMNT, S.SUM_DSCT_AMNT, S.SUM_REMN_AMNT, s.SUM_CASH_AMNT, s.SUM_POS_AMNT, s.SUM_C2C_AMNT, s.SUM_DPST_AMNT, '001' )
	   WHEN MATCHED THEN 
	      UPDATE SET 
	         t.CONT_NUMB += 1,
	         T.SUM_EXPN_AMNT += s.SUM_EXPN_AMNT,
	         T.SUM_DSCT_AMNT += s.SUM_DSCT_AMNT,
	         T.SUM_REMN_AMNT += s.SUM_REMN_AMNT,
	         T.SUM_CASH_AMNT += s.SUM_CASH_AMNT,
	         T.SUM_POS_AMNT += S.SUM_POS_AMNT,
	         T.SUM_C2C_AMNT += S.SUM_C2C_AMNT,
	         T.SUM_DPST_AMNT += S.SUM_DPST_AMNT;
	   
	   MERGE dbo.Statistic_Detail_Request T
	   USING (SELECT sd.CODE AS STSD_CODE, @Rqid AS RQID FROM dbo.Statistic_Detail sd WHERE sd.STIS_CODE = @StisCode) S
	   ON (T.STSD_CODE = S.STSD_CODE AND 
	       T.RQST_RQID = S.RQID)
	   WHEN NOT MATCHED THEN 
	      INSERT (STSD_CODE, RQST_RQID, CODE)
	      VALUES (S.STSD_CODE, s.RQID, dbo.GNRT_NVID_U());	   
	   
	   GOTO L$Loop1;
	   L$EndLoop1:
	   CLOSE [C$Rqst];
	   DEALLOCATE [C$Rqst];
	   
	   -- 2nd * گزارشات بیمه
	   DECLARE C$Rqst CURSOR FOR
	      SELECT r.RQID, f.SEX_TYPE_DNRM, rt.RQTP_DESC, p.SUM_EXPN_PRIC, 
	             p.SUM_PYMT_DSCN_DNRM, (p.SUM_EXPN_PRIC - (p.SUM_RCPT_EXPN_PRIC + p.SUM_PYMT_DSCN_DNRM)) AS SUM_REMN_DNRM
	        FROM dbo.Request r, dbo.Request_Row rr, dbo.Fighter f, 
	             dbo.Payment p, dbo.Request_Type rt
	       WHERE r.RQID = rr.RQST_RQID
	         AND rr.FIGH_FILE_NO = f.FILE_NO
	         AND r.RQID = p.RQST_RQID
	         AND r.RQTP_CODE = rt.CODE
	         AND r.RQTP_CODE IN ('012')
	         AND r.RQST_STAT = '002'
	         AND f.ACTV_TAG_DNRM >= '101'
	         AND CAST(r.SAVE_DATE AS DATE) = @StisDate;
	   
	   OPEN [C$Rqst];
	   L$Loop2:
	   FETCH [C$Rqst] INTO @Rqid, @SexType, @StisDesc, @SumExpnAmnt, @SumDsctAmnt, @SumRemnAmnt
	   
	   IF @@FETCH_STATUS <> 0
	      GOTO L$EndLoop2;
	   
	   MERGE dbo.Statistic_Detail T
	   USING (SELECT @StisCode AS STIS_CODE, 
	                 @StisDesc AS STIS_DESC, 
	                 @SexType AS SEX_TYPE,
	                 @SumExpnAmnt AS SUM_EXPN_AMNT,
	                 @SumDsctAmnt AS SUM_DSCT_AMNT,
	                 @SumRemnAmnt AS SUM_REMN_AMNT,
	                 ISNULL((SELECT SUM(pm.AMNT) FROM dbo.Payment_Method pm WHERE pm.RQRO_RQST_RQID = @Rqid AND pm.RCPT_MTOD = '001'), 0) AS SUM_CASH_AMNT,
	                 ISNULL((SELECT SUM(pm.AMNT) FROM dbo.Payment_Method pm WHERE pm.RQRO_RQST_RQID = @Rqid AND pm.RCPT_MTOD = '003'), 0) AS SUM_POS_AMNT,
	                 ISNULL((SELECT SUM(pm.AMNT) FROM dbo.Payment_Method pm WHERE pm.RQRO_RQST_RQID = @Rqid AND pm.RCPT_MTOD = '005'), 0) AS SUM_DPST_AMNT,
	                 ISNULL((SELECT SUM(pm.AMNT) FROM dbo.Payment_Method pm WHERE pm.RQRO_RQST_RQID = @Rqid AND pm.RCPT_MTOD = '009'), 0) AS SUM_C2C_AMNT) S
	   ON (T.STIS_CODE = S.STIS_CODE AND 
	       T.STIS_DESC = S.STIS_DESC AND 
	       T.SEX_TYPE = S.SEX_TYPE)
	   WHEN NOT MATCHED THEN 
	      INSERT ( STIS_CODE, CODE, STIS_DESC, SEX_TYPE, CONT_NUMB, SUM_EXPN_AMNT, SUM_DSCT_AMNT, SUM_REMN_AMNT, SUM_CASH_AMNT, SUM_POS_AMNT, SUM_C2C_AMNT, SUM_DPST_AMNT, AMNT_TYPE )
	      VALUES ( s.STIS_CODE, dbo.GNRT_NVID_U(), S.STIS_DESC, S.SEX_TYPE, 1, S.SUM_EXPN_AMNT, S.SUM_DSCT_AMNT, S.SUM_REMN_AMNT, s.SUM_CASH_AMNT, s.SUM_POS_AMNT, s.SUM_C2C_AMNT, s.SUM_DPST_AMNT, '006' )
	   WHEN MATCHED THEN 
	      UPDATE SET 
	         t.CONT_NUMB += 1,
	         T.SUM_EXPN_AMNT += s.SUM_EXPN_AMNT,
	         T.SUM_DSCT_AMNT += s.SUM_DSCT_AMNT,
	         T.SUM_REMN_AMNT += s.SUM_REMN_AMNT,
	         T.SUM_CASH_AMNT += s.SUM_CASH_AMNT,
	         T.SUM_POS_AMNT += S.SUM_POS_AMNT,
	         T.SUM_C2C_AMNT += S.SUM_C2C_AMNT,
	         T.SUM_DPST_AMNT += S.SUM_DPST_AMNT;
	   
	   MERGE dbo.Statistic_Detail_Request T
	   USING (SELECT sd.CODE AS STSD_CODE, @Rqid AS RQID FROM dbo.Statistic_Detail sd WHERE sd.STIS_CODE = @StisCode) S
	   ON (T.STSD_CODE = S.STSD_CODE AND 
	       T.RQST_RQID = S.RQID)
	   WHEN NOT MATCHED THEN 
	      INSERT (STSD_CODE, RQST_RQID, CODE)
	      VALUES (S.STSD_CODE, s.RQID, dbo.GNRT_NVID_U());	   
	   
	   GOTO L$Loop2;
	   L$EndLoop2:
	   CLOSE [C$Rqst];
	   DEALLOCATE [C$Rqst];
	   
	   
	   -- 3th * گزارشات مبلغ های افزایش سپرده
	   DECLARE C$Rqst CURSOR FOR
	      SELECT r.RQID, f.SEX_TYPE_DNRM, N'آفزایش سپرده', g.AMNT, 
	             ISNULL((SELECT SUM(gd.AMNT) FROM dbo.Gain_Loss_Rail_Detail gd WHERE gd.GLRL_GLID = g.GLID AND gd.RCPT_MTOD = '014'), 0) AS SUM_DSCT_AMNT,  
	             0 AS SUM_REMN_DNRM
	        FROM dbo.Request r, dbo.Request_Row rr, dbo.Fighter f, 
	             dbo.Gain_Loss_Rial g, dbo.Request_Type rt
	       WHERE r.RQID = rr.RQST_RQID
	         AND rr.FIGH_FILE_NO = f.FILE_NO
	         AND r.RQID = g.RQRO_RQST_RQID
	         AND r.RQTP_CODE = rt.CODE
	         AND r.RQTP_CODE IN ('020')
	         AND r.RQST_STAT = '002'
	         AND f.ACTV_TAG_DNRM >= '101'
	         AND CAST(r.SAVE_DATE AS DATE) = @StisDate
	         AND g.DPST_STAT = '002'
	         AND r.REF_CODE IS NULL;
	   
	   OPEN [C$Rqst];
	   L$Loop3:
	   FETCH [C$Rqst] INTO @Rqid, @SexType, @StisDesc, @SumExpnAmnt, @SumDsctAmnt, @SumRemnAmnt
	   
	   IF @@FETCH_STATUS <> 0
	      GOTO L$EndLoop3;
	   
	   MERGE dbo.Statistic_Detail T
	   USING (SELECT @StisCode AS STIS_CODE, 
	                 @StisDesc AS STIS_DESC, 
	                 @SexType AS SEX_TYPE,
	                 '004' AS AMNT_TYPE,
	                 @SumExpnAmnt AS SUM_EXPN_AMNT,
	                 @SumDsctAmnt AS SUM_DSCT_AMNT,
	                 @SumRemnAmnt AS SUM_REMN_AMNT,
	                 ISNULL((SELECT SUM(gd.AMNT) FROM dbo.Gain_Loss_Rial g, dbo.Gain_Loss_Rail_Detail gd WHERE g.RQRO_RQST_RQID = @Rqid AND g.GLID = gd.GLRL_GLID AND gd.RCPT_MTOD = '001'), 0) AS SUM_CASH_AMNT,
	                 ISNULL((SELECT SUM(gd.AMNT) FROM dbo.Gain_Loss_Rial g, dbo.Gain_Loss_Rail_Detail gd WHERE g.RQRO_RQST_RQID = @Rqid AND g.GLID = gd.GLRL_GLID AND gd.RCPT_MTOD = '003'), 0) AS SUM_POS_AMNT,
	                 ISNULL((SELECT SUM(gd.AMNT) FROM dbo.Gain_Loss_Rial g, dbo.Gain_Loss_Rail_Detail gd WHERE g.RQRO_RQST_RQID = @Rqid AND g.GLID = gd.GLRL_GLID AND gd.RCPT_MTOD = '005'), 0) AS SUM_DPST_AMNT,
	                 ISNULL((SELECT SUM(gd.AMNT) FROM dbo.Gain_Loss_Rial g, dbo.Gain_Loss_Rail_Detail gd WHERE g.RQRO_RQST_RQID = @Rqid AND g.GLID = gd.GLRL_GLID AND gd.RCPT_MTOD = '009'), 0) AS SUM_C2C_AMNT) S
	   ON (T.STIS_CODE = S.STIS_CODE AND 
	       T.STIS_DESC = S.STIS_DESC AND 
	       T.SEX_TYPE = S.SEX_TYPE AND 
	       T.AMNT_TYPE = S.AMNT_TYPE)
	   WHEN NOT MATCHED THEN 
	      INSERT ( STIS_CODE, CODE, STIS_DESC, SEX_TYPE, CONT_NUMB, SUM_EXPN_AMNT, SUM_DSCT_AMNT, SUM_REMN_AMNT, SUM_CASH_AMNT, SUM_POS_AMNT, SUM_C2C_AMNT, SUM_DPST_AMNT, AMNT_TYPE )
	      VALUES ( s.STIS_CODE, dbo.GNRT_NVID_U(), S.STIS_DESC, S.SEX_TYPE, 1, S.SUM_EXPN_AMNT, S.SUM_DSCT_AMNT, S.SUM_REMN_AMNT, s.SUM_CASH_AMNT, s.SUM_POS_AMNT, s.SUM_C2C_AMNT, s.SUM_DPST_AMNT, S.AMNT_TYPE )
	   WHEN MATCHED THEN 
	      UPDATE SET 
	         t.CONT_NUMB += 1,
	         T.SUM_EXPN_AMNT += s.SUM_EXPN_AMNT,
	         T.SUM_DSCT_AMNT += s.SUM_DSCT_AMNT,
	         T.SUM_REMN_AMNT += s.SUM_REMN_AMNT,
	         T.SUM_CASH_AMNT += s.SUM_CASH_AMNT,
	         T.SUM_POS_AMNT += S.SUM_POS_AMNT,
	         T.SUM_C2C_AMNT += S.SUM_C2C_AMNT,
	         T.SUM_DPST_AMNT += S.SUM_DPST_AMNT;
	   
	   MERGE dbo.Statistic_Detail_Request T
	   USING (SELECT sd.CODE AS STSD_CODE, @Rqid AS RQID FROM dbo.Statistic_Detail sd WHERE sd.STIS_CODE = @StisCode) S
	   ON (T.STSD_CODE = S.STSD_CODE AND 
	       T.RQST_RQID = S.RQID)
	   WHEN NOT MATCHED THEN 
	      INSERT (STSD_CODE, RQST_RQID, CODE)
	      VALUES (S.STSD_CODE, s.RQID, dbo.GNRT_NVID_U());	   
	   
	   GOTO L$Loop3;
	   L$EndLoop3:
	   CLOSE [C$Rqst];
	   DEALLOCATE [C$Rqst];
	   
	   -- 4th * گزارشات مبلغ های کاهش سپرده
	   DECLARE C$Rqst CURSOR FOR
	      SELECT r.RQID, f.SEX_TYPE_DNRM, N'برگشت سپرده', - g.AMNT, 
	             ISNULL((SELECT SUM(gd.AMNT) FROM dbo.Gain_Loss_Rail_Detail gd WHERE gd.GLRL_GLID = g.GLID AND gd.RCPT_MTOD = '014'), 0) AS SUM_DSCT_AMNT,  
	             0 AS SUM_REMN_DNRM
	        FROM dbo.Request r, dbo.Request_Row rr, dbo.Fighter f, 
	             dbo.Gain_Loss_Rial g, dbo.Request_Type rt
	       WHERE r.RQID = rr.RQST_RQID
	         AND rr.FIGH_FILE_NO = f.FILE_NO
	         AND r.RQID = g.RQRO_RQST_RQID
	         AND r.RQTP_CODE = rt.CODE
	         AND r.RQTP_CODE IN ('020')
	         AND r.RQST_STAT = '002'
	         AND f.ACTV_TAG_DNRM >= '101'
	         AND CAST(r.SAVE_DATE AS DATE) = @StisDate
	         AND g.DPST_STAT = '001';
	   
	   OPEN [C$Rqst];
	   L$Loop4:
	   FETCH [C$Rqst] INTO @Rqid, @SexType, @StisDesc, @SumExpnAmnt, @SumDsctAmnt, @SumRemnAmnt
	   
	   IF @@FETCH_STATUS <> 0
	      GOTO L$EndLoop4;
	   
	   MERGE dbo.Statistic_Detail T
	   USING (SELECT @StisCode AS STIS_CODE, 
	                 @StisDesc AS STIS_DESC, 
	                 @SexType AS SEX_TYPE,
	                 '005' AS AMNT_TYPE,
	                 @SumExpnAmnt AS SUM_EXPN_AMNT,
	                 @SumDsctAmnt AS SUM_DSCT_AMNT,
	                 @SumRemnAmnt AS SUM_REMN_AMNT,
	                 -ISNULL((SELECT SUM(gd.AMNT) FROM dbo.Gain_Loss_Rial g, dbo.Gain_Loss_Rail_Detail gd WHERE g.RQRO_RQST_RQID = @Rqid AND g.GLID = gd.GLRL_GLID AND gd.RCPT_MTOD = '001'), 0) AS SUM_CASH_AMNT,
	                 -ISNULL((SELECT SUM(gd.AMNT) FROM dbo.Gain_Loss_Rial g, dbo.Gain_Loss_Rail_Detail gd WHERE g.RQRO_RQST_RQID = @Rqid AND g.GLID = gd.GLRL_GLID AND gd.RCPT_MTOD = '003'), 0) AS SUM_POS_AMNT,
	                 -ISNULL((SELECT SUM(gd.AMNT) FROM dbo.Gain_Loss_Rial g, dbo.Gain_Loss_Rail_Detail gd WHERE g.RQRO_RQST_RQID = @Rqid AND g.GLID = gd.GLRL_GLID AND gd.RCPT_MTOD = '005'), 0) AS SUM_DPST_AMNT,
	                 -ISNULL((SELECT SUM(gd.AMNT) FROM dbo.Gain_Loss_Rial g, dbo.Gain_Loss_Rail_Detail gd WHERE g.RQRO_RQST_RQID = @Rqid AND g.GLID = gd.GLRL_GLID AND gd.RCPT_MTOD = '009'), 0) AS SUM_C2C_AMNT) S
	   ON (T.STIS_CODE = S.STIS_CODE AND 
	       T.STIS_DESC = S.STIS_DESC AND 
	       T.SEX_TYPE = S.SEX_TYPE AND 
	       T.AMNT_TYPE = S.AMNT_TYPE)
	   WHEN NOT MATCHED THEN 
	      INSERT ( STIS_CODE, CODE, STIS_DESC, SEX_TYPE, CONT_NUMB, SUM_EXPN_AMNT, SUM_DSCT_AMNT, SUM_REMN_AMNT, SUM_CASH_AMNT, SUM_POS_AMNT, SUM_C2C_AMNT, SUM_DPST_AMNT, AMNT_TYPE )
	      VALUES ( s.STIS_CODE, dbo.GNRT_NVID_U(), S.STIS_DESC, S.SEX_TYPE, 1, S.SUM_EXPN_AMNT, S.SUM_DSCT_AMNT, S.SUM_REMN_AMNT, s.SUM_CASH_AMNT, s.SUM_POS_AMNT, s.SUM_C2C_AMNT, s.SUM_DPST_AMNT, S.AMNT_TYPE )
	   WHEN MATCHED THEN 
	      UPDATE SET 
	         t.CONT_NUMB += 1,
	         T.SUM_EXPN_AMNT += s.SUM_EXPN_AMNT,
	         T.SUM_DSCT_AMNT += s.SUM_DSCT_AMNT,
	         T.SUM_REMN_AMNT += s.SUM_REMN_AMNT,
	         T.SUM_CASH_AMNT += s.SUM_CASH_AMNT,
	         T.SUM_POS_AMNT += S.SUM_POS_AMNT,
	         T.SUM_C2C_AMNT += S.SUM_C2C_AMNT,
	         T.SUM_DPST_AMNT += S.SUM_DPST_AMNT;
	   
	   MERGE dbo.Statistic_Detail_Request T
	   USING (SELECT sd.CODE AS STSD_CODE, @Rqid AS RQID FROM dbo.Statistic_Detail sd WHERE sd.STIS_CODE = @StisCode) S
	   ON (T.STSD_CODE = S.STSD_CODE AND 
	       T.RQST_RQID = S.RQID)
	   WHEN NOT MATCHED THEN 
	      INSERT (STSD_CODE, RQST_RQID, CODE)
	      VALUES (S.STSD_CODE, s.RQID, dbo.GNRT_NVID_U());	   
	   
	   GOTO L$Loop4;
	   L$EndLoop4:
	   CLOSE [C$Rqst];
	   DEALLOCATE [C$Rqst];
	   
	   -- 5th * گزارش های سالن های بیلیارد، بولینگ، شهربازی و کارت عضویت مجموعه
	   DECLARE C$Rqst CURSOR FOR
	      SELECT r.RQID, f.SEX_TYPE_DNRM, r.REF_CODE,
	             p.SUM_PYMT_DSCN_DNRM, (p.SUM_EXPN_PRIC - (p.SUM_RCPT_EXPN_PRIC + p.SUM_PYMT_DSCN_DNRM)) AS SUM_REMN_DNRM
	        FROM dbo.Request r, dbo.Request_Row rr, dbo.Fighter f, 
	             dbo.Payment p
	       WHERE r.RQID = rr.RQST_RQID
	         AND rr.FIGH_FILE_NO = f.FILE_NO
	         AND r.RQID = p.RQST_RQID
	         AND r.RQTP_CODE IN ('016')
	         AND r.RQST_STAT = '002'
	         AND f.ACTV_TAG_DNRM >= '101'
	         AND r.CRET_BY != 'APPUSER'
	         AND CAST(r.SAVE_DATE AS DATE) = @StisDate;
	   
	   OPEN [C$Rqst];
	   L$Loop5:
	   FETCH [C$Rqst] INTO @Rqid, @SexType, @RefCode, @SumDsctAmnt, @SumRemnAmnt
	   
	   IF @@FETCH_STATUS <> 0
	      GOTO L$EndLoop5;
	   
	   -- اول از شما باید مشخص کنیم که این درخواست چه گروه درآمدی را شامل میشود
	   DECLARE C$Gexp CURSOR FOR
	      SELECT dbo.GET_GEXP_U(e.GROP_CODE), (pd.EXPN_PRIC * pd.QNTY) AS SUM_EXPN_PRIC
	        FROM dbo.Payment_Detail pd, dbo.Expense e
	       WHERE pd.PYMT_RQST_RQID = @Rqid
	         AND pd.EXPN_CODE = e.CODE;
	   
	   OPEN [C$Gexp];
	   L$Loop6:
	   FETCH [C$Gexp] INTO @StisDesc, @SumExpnAmnt;
	   
	   IF @@FETCH_STATUS <> 0
	      GOTO L$EndLoop6;
	   
	   -- مجموعه هتل المپیک باقری	   
	   IF (@StisDesc IN ( N'بیلیارد', N'بولینگ', N'شهربازی'))
	   BEGIN
	      MERGE dbo.Statistic_Detail T
	      USING (SELECT @StisCode AS STIS_CODE, 
	                    @StisDesc AS STIS_DESC, 
	                    @SexType AS SEX_TYPE,
	                    @SumExpnAmnt AS SUM_EXPN_AMNT,
	                    0 AS SUM_DSCT_AMNT,
	                    0 AS SUM_REMN_AMNT,
	                    0 AS SUM_CASH_AMNT,
	                    0 AS SUM_POS_AMNT,
	                    ISNULL((SELECT SUM(pm.AMNT) FROM dbo.Payment_Method pm WHERE pm.RQRO_RQST_RQID = @Rqid AND pm.RCPT_MTOD = '005'), 0) AS SUM_DPST_AMNT,
	                    0 AS SUM_C2C_AMNT) S
	      ON (T.STIS_CODE = S.STIS_CODE AND 
	          T.STIS_DESC = S.STIS_DESC AND 
	          T.SEX_TYPE = S.SEX_TYPE)
	      WHEN NOT MATCHED THEN 
	         INSERT ( STIS_CODE, CODE, STIS_DESC, SEX_TYPE, CONT_NUMB, SUM_EXPN_AMNT, SUM_DSCT_AMNT, SUM_REMN_AMNT, SUM_CASH_AMNT, SUM_POS_AMNT, SUM_C2C_AMNT, SUM_DPST_AMNT, AMNT_TYPE )
	         VALUES ( s.STIS_CODE, dbo.GNRT_NVID_U(), S.STIS_DESC, S.SEX_TYPE, 1, S.SUM_EXPN_AMNT, S.SUM_DSCT_AMNT, S.SUM_REMN_AMNT, s.SUM_CASH_AMNT, s.SUM_POS_AMNT, s.SUM_C2C_AMNT, s.SUM_DPST_AMNT, '001' )
	      WHEN MATCHED THEN 
	         UPDATE SET 
	            t.CONT_NUMB += 1,
	            T.SUM_EXPN_AMNT += s.SUM_EXPN_AMNT,
	            T.SUM_DSCT_AMNT += s.SUM_DSCT_AMNT,
	            T.SUM_REMN_AMNT += s.SUM_REMN_AMNT,
	            T.SUM_CASH_AMNT += s.SUM_CASH_AMNT,
	            T.SUM_POS_AMNT += S.SUM_POS_AMNT,
	            T.SUM_C2C_AMNT += S.SUM_C2C_AMNT,
	            T.SUM_DPST_AMNT += S.SUM_DPST_AMNT;
	   END 
	   ELSE IF (@StisDesc IN (N'عضویت مجموعه'))
	   BEGIN
	      MERGE dbo.Statistic_Detail T
	      USING (SELECT @StisCode AS STIS_CODE, 
	                    @StisDesc AS STIS_DESC, 
	                    @SexType AS SEX_TYPE,
	                    @SumExpnAmnt AS SUM_EXPN_AMNT,
	                    0 AS SUM_DSCT_AMNT,
	                    0 AS SUM_REMN_AMNT,
	                    ISNULL((SELECT SUM(pm.AMNT) FROM dbo.Payment_Method pm WHERE pm.RQRO_RQST_RQID = @Rqid AND pm.RCPT_MTOD = '001'), 0) AS SUM_CASH_AMNT,
	                    ISNULL((SELECT SUM(pm.AMNT) FROM dbo.Payment_Method pm WHERE pm.RQRO_RQST_RQID = @Rqid AND pm.RCPT_MTOD = '003'), 0) AS SUM_POS_AMNT,
	                    ISNULL((SELECT SUM(pm.AMNT) FROM dbo.Payment_Method pm WHERE pm.RQRO_RQST_RQID = @Rqid AND pm.RCPT_MTOD = '005'), 0) AS SUM_DPST_AMNT,
	                    ISNULL((SELECT SUM(pm.AMNT) FROM dbo.Payment_Method pm WHERE pm.RQRO_RQST_RQID = @Rqid AND pm.RCPT_MTOD = '009'), 0) AS SUM_C2C_AMNT) S
	      ON (T.STIS_CODE = S.STIS_CODE AND 
	          T.STIS_DESC = S.STIS_DESC AND 
	          T.SEX_TYPE = S.SEX_TYPE)
	      WHEN NOT MATCHED THEN 
	         INSERT ( STIS_CODE, CODE, STIS_DESC, SEX_TYPE, CONT_NUMB, SUM_EXPN_AMNT, SUM_DSCT_AMNT, SUM_REMN_AMNT, SUM_CASH_AMNT, SUM_POS_AMNT, SUM_C2C_AMNT, SUM_DPST_AMNT, AMNT_TYPE )
	         VALUES ( s.STIS_CODE, dbo.GNRT_NVID_U(), S.STIS_DESC, S.SEX_TYPE, 1, S.SUM_EXPN_AMNT, S.SUM_DSCT_AMNT, S.SUM_REMN_AMNT, s.SUM_CASH_AMNT, s.SUM_POS_AMNT, s.SUM_C2C_AMNT, s.SUM_DPST_AMNT, '001' )
	      WHEN MATCHED THEN 
	         UPDATE SET 
	            t.CONT_NUMB += 1,
	            T.SUM_EXPN_AMNT += s.SUM_EXPN_AMNT,
	            T.SUM_DSCT_AMNT += s.SUM_DSCT_AMNT,
	            T.SUM_REMN_AMNT += s.SUM_REMN_AMNT,
	            T.SUM_CASH_AMNT += s.SUM_CASH_AMNT,
	            T.SUM_POS_AMNT += S.SUM_POS_AMNT,
	            T.SUM_C2C_AMNT += S.SUM_C2C_AMNT,
	            T.SUM_DPST_AMNT += S.SUM_DPST_AMNT;
	   END	   
	   -- مجموعه هتل المپیک باقری
	   
	   GOTO L$Loop6;
	   L$EndLoop6:
	   CLOSE [C$Gexp];
	   DEALLOCATE [C$Gexp];	   
	   
	   MERGE dbo.Statistic_Detail_Request T
	   USING (SELECT sd.CODE AS STSD_CODE, @Rqid AS RQID FROM dbo.Statistic_Detail sd WHERE sd.STIS_CODE = @StisCode) S
	   ON (T.STSD_CODE = S.STSD_CODE AND 
	       T.RQST_RQID = S.RQID)
	   WHEN NOT MATCHED THEN 
	      INSERT (STSD_CODE, RQST_RQID, CODE)
	      VALUES (S.STSD_CODE, s.RQID, dbo.GNRT_NVID_U());	   
	   
	   GOTO L$Loop5;
	   L$EndLoop5:
	   CLOSE [C$Rqst];
	   DEALLOCATE [C$Rqst];
	   
	   -- 6th Cafe, Resturant, Pool Shop
	   DECLARE C$Rqst CURSOR FOR
	      SELECT r.RQID, f.SEX_TYPE_DNRM, N'کافه، رستوران، فروشگاه استخر', r.REF_CODE, p.SUM_EXPN_PRIC, 
	             p.SUM_PYMT_DSCN_DNRM, (p.SUM_EXPN_PRIC - (p.SUM_RCPT_EXPN_PRIC + p.SUM_PYMT_DSCN_DNRM)) AS SUM_REMN_DNRM
	        FROM dbo.Request r, dbo.Request_Row rr, dbo.Fighter f, 
	             dbo.Payment p
	       WHERE r.RQID = rr.RQST_RQID
	         AND rr.FIGH_FILE_NO = f.FILE_NO
	         AND r.RQID = p.RQST_RQID
	         AND r.RQTP_CODE IN ('016')
	         AND r.RQST_STAT = '002'
	         AND f.ACTV_TAG_DNRM >= '101'
	         AND r.CRET_BY = 'APPUSER'
	         AND CAST(r.SAVE_DATE AS DATE) = @StisDate;
	   
	   OPEN [C$Rqst];
	   L$Loop7:
	   FETCH [C$Rqst] INTO @Rqid, @SexType, @StisDesc, @RefCode, @SumExpnAmnt, @SumDsctAmnt, @SumRemnAmnt
	   
	   IF @@FETCH_STATUS <> 0
	      GOTO L$EndLoop7;
	   
	   MERGE dbo.Statistic_Detail T
	      USING (SELECT @StisCode AS STIS_CODE, 
	                    @StisDesc AS STIS_DESC, 
	                    @SexType AS SEX_TYPE,
	                    @SumExpnAmnt AS SUM_EXPN_AMNT,
	                    @SumDsctAmnt AS SUM_DSCT_AMNT,
	                    @SumRemnAmnt AS SUM_REMN_AMNT,
	                    ISNULL((SELECT SUM(os.AMNT) FROM iRoboTech.dbo.Order_State os WHERE os.ORDR_CODE = @RefCode AND os.WLDT_CODE IS NULL AND os.RCPT_MTOD = '001'), 0) AS SUM_CASH_AMNT,
	                    ISNULL((SELECT SUM(os.AMNT) FROM iRoboTech.dbo.Order_State os WHERE os.ORDR_CODE = @RefCode AND os.WLDT_CODE IS NULL AND os.RCPT_MTOD = '003'), 0) AS SUM_POS_AMNT,
	                    ISNULL((SELECT SUM(os.AMNT) FROM iRoboTech.dbo.Order_State os WHERE os.ORDR_CODE = @RefCode AND os.WLDT_CODE IS NULL AND os.RCPT_MTOD = '005'), 0) AS SUM_DPST_AMNT,
	                    ISNULL((SELECT SUM(os.AMNT) FROM iRoboTech.dbo.Order_State os WHERE os.ORDR_CODE = @RefCode AND os.WLDT_CODE IS NULL AND os.RCPT_MTOD = '009'), 0) AS SUM_C2C_AMNT) S
	      ON (T.STIS_CODE = S.STIS_CODE AND 
	          T.STIS_DESC = S.STIS_DESC AND 
	          T.SEX_TYPE = S.SEX_TYPE)
	      WHEN NOT MATCHED THEN 
	         INSERT ( STIS_CODE, CODE, STIS_DESC, SEX_TYPE, CONT_NUMB, SUM_EXPN_AMNT, SUM_DSCT_AMNT, SUM_REMN_AMNT, SUM_CASH_AMNT, SUM_POS_AMNT, SUM_C2C_AMNT, SUM_DPST_AMNT, AMNT_TYPE )
	         VALUES ( s.STIS_CODE, dbo.GNRT_NVID_U(), S.STIS_DESC, S.SEX_TYPE, 1, S.SUM_EXPN_AMNT, S.SUM_DSCT_AMNT, S.SUM_REMN_AMNT, s.SUM_CASH_AMNT, s.SUM_POS_AMNT, s.SUM_C2C_AMNT, s.SUM_DPST_AMNT, '001' )
	      WHEN MATCHED THEN 
	         UPDATE SET 
	            t.CONT_NUMB += 1,
	            T.SUM_EXPN_AMNT += s.SUM_EXPN_AMNT,
	            T.SUM_DSCT_AMNT += s.SUM_DSCT_AMNT,
	            T.SUM_REMN_AMNT += s.SUM_REMN_AMNT,
	            T.SUM_CASH_AMNT += s.SUM_CASH_AMNT,
	            T.SUM_POS_AMNT += S.SUM_POS_AMNT,
	            T.SUM_C2C_AMNT += S.SUM_C2C_AMNT,
	            T.SUM_DPST_AMNT += S.SUM_DPST_AMNT;
      	   
	   MERGE dbo.Statistic_Detail_Request T
	   USING (SELECT sd.CODE AS STSD_CODE, @Rqid AS RQID FROM dbo.Statistic_Detail sd WHERE sd.STIS_CODE = @StisCode) S
	   ON (T.STSD_CODE = S.STSD_CODE AND 
	       T.RQST_RQID = S.RQID)
	   WHEN NOT MATCHED THEN 
	      INSERT (STSD_CODE, RQST_RQID, CODE)
	      VALUES (S.STSD_CODE, s.RQID, dbo.GNRT_NVID_U());	   
	   
	   GOTO L$Loop7;
	   L$EndLoop7:
	   CLOSE [C$Rqst];
	   DEALLOCATE [C$Rqst];
	   
	   -- گزارش درامد متفرقه
	   INSERT INTO dbo.Statistic_Detail
      ( STIS_CODE ,CODE ,STIS_DESC ,SEX_TYPE ,CONT_NUMB ,
      SUM_EXPN_AMNT ,SUM_DSCT_AMNT ,SUM_CASH_AMNT ,
      SUM_POS_AMNT ,SUM_C2C_AMNT ,SUM_DPST_AMNT ,SUM_REMN_AMNT ,
      AMNT_TYPE ,RECT_TYPE )
      SELECT @StisCode, dbo.GNRT_NVID_U(), N'درآمدهای متفرقه', T.SEX_TYPE_DNRM, T.CONT_NUMB,
             T.SUM_EXPN_AMNT, T.SUM_DSCT_AMNT, T.SUM_CASH_AMNT, 
             T.SUM_POS_AMNT, T.SUM_C2C_AMNT, T.SUM_DPST_AMNT, T.SUM_REMN_AMNT,
             '001', '001'
        FROM (
         SELECT f.SEX_TYPE_DNRM, 
                COUNT(r.RQID) AS CONT_NUMB, 
                SUM(p.SUM_EXPN_PRIC + p.Sum_Expn_Extr_Prct) AS SUM_EXPN_AMNT, 
                SUM(p.SUM_PYMT_DSCN_DNRM) AS SUM_DSCT_AMNT,             
                ISNULL((SELECT SUM(pm.AMNT) FROM dbo.Payment_Method pm WHERE CAST(pm.ACTN_DATE AS DATE) = @StisDate AND pm.RCPT_MTOD = '001'), 0) AS SUM_CASH_AMNT,
                ISNULL((SELECT SUM(pm.AMNT) FROM dbo.Payment_Method pm WHERE CAST(pm.ACTN_DATE AS DATE) = @StisDate AND pm.RCPT_MTOD = '003'), 0) AS SUM_POS_AMNT,
                ISNULL((SELECT SUM(pm.AMNT) FROM dbo.Payment_Method pm WHERE CAST(pm.ACTN_DATE AS DATE) = @StisDate AND pm.RCPT_MTOD = '009'), 0) AS SUM_C2C_AMNT,
                ISNULL((SELECT SUM(pm.AMNT) FROM dbo.Payment_Method pm WHERE CAST(pm.ACTN_DATE AS DATE) = @StisDate AND pm.RCPT_MTOD = '005'), 0) AS SUM_DPST_AMNT,
                SUM((p.SUM_EXPN_PRIC + p.Sum_Expn_Extr_Prct) - (p.SUM_RCPT_EXPN_PRIC + p.SUM_PYMT_DSCN_DNRM)) AS SUM_REMN_AMNT
           FROM Request r, Request_Row rr, Fighter f, Payment p
          WHERE r.RQID = rr.RQST_RQID
            AND rr.FIGH_FILE_NO = f.FILE_NO
            AND r.RQID = p.RQST_RQID
            AND r.RQTP_CODE = '016'
            AND f.ACTV_TAG_DNRM >= '101'
            AND r.RQST_STAT = '002'
            AND CAST(r.SAVE_DATE AS DATE) = @StisDate
          GROUP BY f.Sex_Type_Dnrm ) T;
	   
	   -- 7th * Summery
	   INSERT INTO dbo.Statistic_Detail ( STIS_CODE ,CODE ,STIS_DESC )
	   VALUES  ( @StisCode ,dbo.GNRT_NVID_U() ,N'***** گزارش ریز درآمدها *****' );
	   
	   INSERT INTO dbo.Statistic_Detail
      ( STIS_CODE ,CODE ,STIS_DESC ,SEX_TYPE ,CONT_NUMB ,AMNT_TYPE ,RECT_TYPE )
      SELECT @StisCode, dbo.GNRT_NVID_U(), T.STIS_DESC, t.SEX_TYPE_DNRM, t.CONT_NUMB, '001', '001'
        FROM (
      SELECT M.MTOD_DESC + N' - ' + c.CTGY_DESC AS STIS_DESC, f.SEX_TYPE_DNRM, COUNT(r.RQID) AS CONT_NUMB
        FROM dbo.Request r, dbo.Request_Row rr, dbo.Fighter f, 
             dbo.Payment p, dbo.Payment_Detail pd, dbo.Method m, dbo.Category_Belt c
       WHERE r.RQID = rr.RQST_RQID
         AND rr.FIGH_FILE_NO = f.FILE_NO
         AND r.RQID = p.RQST_RQID
         AND p.RQST_RQID = pd.PYMT_RQST_RQID
         AND pd.MTOD_CODE_DNRM = m.CODE
         AND pd.CTGY_CODE_DNRM = c.CODE
         AND c.MTOD_CODE = m.CODE
         AND r.RQTP_CODE IN ('001', '009')
         AND r.RQST_STAT = '002'
         AND f.ACTV_TAG_DNRM >= '101'
         AND CAST(r.SAVE_DATE AS DATE) = @StisDate
       GROUP BY M.MTOD_DESC + N' - ' + c.CTGY_DESC, f.SEX_TYPE_DNRM
       ) T
       ORDER BY t.STIS_DESC;
	   
	   --INSERT INTO dbo.Statistic_Detail
    --  ( STIS_CODE ,CODE ,STIS_DESC ,SEX_TYPE ,CONT_NUMB ,AMNT_TYPE ,RECT_TYPE )
    --  SELECT @StisCode, dbo.GNRT_NVID_U(), N'بیمه', t.SEX_TYPE_DNRM, t.CONT_NUMB, '006', '001'
    --    FROM (
    --  SELECT f.SEX_TYPE_DNRM, COUNT(r.RQID) AS CONT_NUMB
    --    FROM dbo.Request r, dbo.Request_Row rr, dbo.Fighter f, 
    --         dbo.Payment p, dbo.Payment_Detail pd
    --   WHERE r.RQID = rr.RQST_RQID
    --     AND rr.FIGH_FILE_NO = f.FILE_NO
    --     AND r.RQID = p.RQST_RQID
    --     AND p.RQST_RQID = pd.PYMT_RQST_RQID
    --     AND r.RQTP_CODE IN ('012')
    --     AND r.RQST_STAT = '002'
    --     AND f.ACTV_TAG_DNRM >= '101'
    --     AND CAST(r.SAVE_DATE AS DATE) = @StisDate
    --   GROUP BY f.SEX_TYPE_DNRM
    --   ) T
    --   ORDER BY t.SEX_TYPE_DNRM;
	   
	   --INSERT INTO dbo.Statistic_Detail
    --  ( STIS_CODE ,CODE ,STIS_DESC ,SEX_TYPE ,CONT_NUMB ,AMNT_TYPE ,RECT_TYPE )
    --  SELECT @StisCode, dbo.GNRT_NVID_U(), N'افزایش سپرده', t.SEX_TYPE_DNRM, t.CONT_NUMB, '006', '001'
    --    FROM (
    --  SELECT f.SEX_TYPE_DNRM, COUNT(r.RQID) AS CONT_NUMB
    --    FROM dbo.Request r, dbo.Request_Row rr, dbo.Fighter f, 
    --         dbo.Gain_Loss_Rial g, dbo.Request_Type rt
    --   WHERE r.RQID = rr.RQST_RQID
    --     AND rr.FIGH_FILE_NO = f.FILE_NO
    --     AND r.RQID = g.RQRO_RQST_RQID
    --     AND r.RQTP_CODE = rt.CODE
    --     AND r.RQTP_CODE IN ('020')
    --     AND r.RQST_STAT = '002'
    --     AND f.ACTV_TAG_DNRM >= '101'
    --     AND CAST(r.SAVE_DATE AS DATE) = @StisDate
    --     AND g.DPST_STAT = '002'
    --     AND r.REF_CODE IS NULL
    --   GROUP BY f.SEX_TYPE_DNRM
    --   ) T
    --   ORDER BY t.SEX_TYPE_DNRM;
	   
	   INSERT INTO dbo.Statistic_Detail
      ( STIS_CODE ,CODE ,STIS_DESC ,SEX_TYPE ,CONT_NUMB ,AMNT_TYPE ,RECT_TYPE )
      SELECT @StisCode, dbo.GNRT_NVID_U(), T.STIS_DESC, t.SEX_TYPE_DNRM, t.CONT_NUMB, '001', '001'
        FROM (
      SELECT pd.PYDT_DESC AS STIS_DESC, f.SEX_TYPE_DNRM, COUNT(r.RQID) AS CONT_NUMB
        FROM dbo.Request r, dbo.Request_Row rr, dbo.Fighter f, 
             dbo.Payment p, dbo.Payment_Detail pd
       WHERE r.RQID = rr.RQST_RQID
         AND rr.FIGH_FILE_NO = f.FILE_NO
         AND r.RQID = p.RQST_RQID
         AND p.RQST_RQID = pd.PYMT_RQST_RQID
         AND r.RQTP_CODE IN ('016')
         AND r.RQST_STAT = '002'
         AND f.ACTV_TAG_DNRM >= '101'
         AND CAST(r.SAVE_DATE AS DATE) = @StisDate
       GROUP BY pd.PYDT_DESC, f.SEX_TYPE_DNRM
       ) T
       ORDER BY t.STIS_DESC;
	   
	   
	   -- 7th * Summery
	   INSERT INTO dbo.Statistic_Detail ( STIS_CODE ,CODE ,STIS_DESC )
	   VALUES  ( @StisCode ,dbo.GNRT_NVID_U() ,N'***** گزارش صندوقداران *****' );
	   
	   -- 8th * Cashier Amount Type Summery
	   SET @SexType = '003';
	   MERGE dbo.Statistic_Detail T
	   USING (
	      SELECT T.STIS_CODE, T.STIS_DESC, T.SEX_TYPE, 
	             SUM(T.SUM_CASH_AMNT) AS SUM_CASH_AMNT,
	             SUM(T.SUM_POS_AMNT) AS SUM_POS_AMNT,
	             SUM(T.SUM_C2C_AMNT) AS SUM_C2C_AMNT
	        FROM (
	         -- مختص نرم افزار ارتا
	         SELECT @StisCode AS STIS_CODE,
	                u.USER_NAME AS STIS_DESC, 
	                @SexType AS SEX_TYPE,
	                ISNULL(SUM(CASE pm.RCPT_MTOD WHEN '001' THEN pm.AMNT ELSE 0 END), 0) AS SUM_CASH_AMNT,
	                ISNULL(SUM(CASE pm.RCPT_MTOD WHEN '003' THEN pm.AMNT ELSE 0 END), 0) AS SUM_POS_AMNT,
	                ISNULL(SUM(CASE pm.RCPT_MTOD WHEN '009' THEN pm.AMNT ELSE 0 END), 0) AS SUM_C2C_AMNT
	           FROM dbo.Payment_Method pm, dbo.V#Users u
	          WHERE CAST(pm.ACTN_DATE AS DATE) = @StisDate
	            AND pm.RCPT_MTOD IN ('001', '003', '009')
	            AND pm.CRET_BY = u.USER_DB
	          GROUP BY u.USER_NAME
	         UNION ALL
	         SELECT @StisCode AS STIS_CODE,
	                u.USER_NAME AS STIS_DESC, 
	                @SexType AS SEX_TYPE,
	                ISNULL(SUM(CASE pm.RCPT_MTOD WHEN '001' THEN pm.AMNT ELSE 0 END), 0) AS SUM_CASH_AMNT,
	                ISNULL(SUM(CASE pm.RCPT_MTOD WHEN '003' THEN pm.AMNT ELSE 0 END), 0) AS SUM_POS_AMNT,
	                ISNULL(SUM(CASE pm.RCPT_MTOD WHEN '009' THEN pm.AMNT ELSE 0 END), 0) AS SUM_C2C_AMNT
	           FROM dbo.Gain_Loss_Rail_Detail pm, dbo.Gain_Loss_Rial g, dbo.V#Users u
	          WHERE pm.GLRL_GLID = g.GLID
	            AND g.CONF_STAT = '002'
	            AND g.DPST_STAT = '002'
	            AND CAST(g.PAID_DATE AS DATE) = @StisDate
	            AND pm.RCPT_MTOD IN ('001', '003', '009')
	            AND pm.CRET_BY = u.USER_DB
	          GROUP BY u.USER_NAME
	         UNION ALL
	         SELECT @StisCode AS STIS_CODE,
	                u.USER_NAME AS STIS_DESC, 
	                @SexType AS SEX_TYPE,
	                ISNULL(SUM(CASE pm.RCPT_MTOD WHEN '001' THEN pm.AMNT ELSE 0 END), 0) AS SUM_CASH_AMNT,
	                ISNULL(SUM(CASE pm.RCPT_MTOD WHEN '003' THEN pm.AMNT ELSE 0 END), 0) AS SUM_POS_AMNT,
	                ISNULL(SUM(CASE pm.RCPT_MTOD WHEN '009' THEN pm.AMNT ELSE 0 END), 0) AS SUM_C2C_AMNT
	           FROM iRoboTech.dbo.Order_State pm, dbo.V#Users u, iRoboTech.dbo.[Order] o
	          WHERE CAST(pm.STAT_DATE AS DATE) = @StisDate
	            AND pm.ORDR_CODE = o.CODE
	            AND o.ORDR_STAT IN ('004', '009')
	            AND pm.RCPT_MTOD IN ('001', '003', '009')
	            AND pm.AMNT_TYPE = '007'
	            AND u.USER_DB = pm.CRET_BY
	          GROUP BY u.USER_NAME
	       ) T
	       GROUP BY T.STIS_CODE, T.STIS_DESC, T.SEX_TYPE
	   ) S
	   ON (T.STIS_CODE = S.STIS_CODE AND
	       T.STIS_DESC = S.STIS_DESC AND
	       T.SEX_TYPE = S.SEX_TYPE)
	   WHEN NOT MATCHED THEN 
	      INSERT ( STIS_CODE, CODE, STIS_DESC, SEX_TYPE, SUM_EXPN_AMNT, SUM_DSCT_AMNT, SUM_REMN_AMNT, SUM_CASH_AMNT, SUM_POS_AMNT, SUM_C2C_AMNT, SUM_DPST_AMNT, AMNT_TYPE )
	      VALUES ( s.STIS_CODE, dbo.GNRT_NVID_U(), S.STIS_DESC, S.SEX_TYPE, S.SUM_CASH_AMNT + S.SUM_POS_AMNT + S.SUM_C2C_AMNT, 0, 0, s.SUM_CASH_AMNT, s.SUM_POS_AMNT, s.SUM_C2C_AMNT, 0, '001' )
      WHEN MATCHED THEN 
         UPDATE SET             
            T.SUM_EXPN_AMNT += s.SUM_CASH_AMNT + s.SUM_POS_AMNT + s.SUM_C2C_AMNT,
            T.SUM_CASH_AMNT += s.SUM_CASH_AMNT,
            T.SUM_POS_AMNT += S.SUM_POS_AMNT,
            T.SUM_C2C_AMNT += S.SUM_C2C_AMNT;
	   
	   -- 7th * Summery
	   --INSERT INTO dbo.Statistic_Detail ( STIS_CODE ,CODE )
	   --VALUES  ( @StisCode ,dbo.GNRT_NVID_U() );
	   
	   INSERT INTO dbo.Statistic_Detail( STIS_CODE ,CODE ,STIS_DESC , SEX_TYPE,SUM_EXPN_AMNT ,SUM_CASH_AMNT ,SUM_POS_AMNT ,SUM_C2C_AMNT ,AMNT_TYPE )
	   SELECT @StisCode, dbo.GNRT_NVID_U(), N'***** گزارش جمع کل *****', /*'003'*/NULL,
	          ISNULL(SUM(sd.SUM_EXPN_AMNT), 0),
	          ISNULL(SUM(sd.SUM_CASH_AMNT), 0),
	          ISNULL(SUM(sd.SUM_POS_AMNT), 0),
	          ISNULL(SUM(sd.SUM_C2C_AMNT), 0),
	          /*'001'*/NULL
	     FROM dbo.Statistic_Detail sd
	    WHERE sd.STIS_CODE = @StisCode
	      AND sd.SEX_TYPE = '003';	   
	   
	   -- علامت گذاری رکورد های خروجی اول
	   UPDATE dbo.Statistic_Detail 
	      SET RECT_TYPE = '001'
	    WHERE STIS_CODE = @StisCode AND RECT_TYPE IS NULL;
	   
	   ----------------------------------------------------------------------------------------
	   
	   -- 7th * Summery
	   INSERT INTO dbo.Statistic_Detail ( STIS_CODE ,CODE ,STIS_DESC )
	   VALUES  ( @StisCode ,dbo.GNRT_NVID_U() ,N'***** گزارش درآمدها *****' );
	   
	   -- ایجاد گزارش نوع دوم
	   INSERT INTO dbo.Statistic_Detail
      ( STIS_CODE ,CODE ,STIS_DESC ,CONT_NUMB ,SUM_EXPN_AMNT ,SUM_DSCT_AMNT ,SUM_CASH_AMNT ,SUM_POS_AMNT ,
        SUM_C2C_AMNT ,SUM_DPST_AMNT ,SUM_REMN_AMNT, SEX_TYPE, AMNT_TYPE )
      SELECT @StisCode, dbo.GNRT_NVID_U(), t.STIS_DESC, T.CONT_NUMB,
             t.SUM_EXPN_AMNT, t.SUM_DSCT_AMNT, t.SUM_CASH_AMNT, t.SUM_POS_AMNT, t.SUM_C2C_AMNT, t.SUM_DPST_AMNT,
             t.SUM_REMN_AMNT, '003', '001'
        FROM (
         SELECT sd.STIS_DESC, 
                SUM(sd.CONT_NUMB) AS CONT_NUMB,
                SUM(SUM_EXPN_AMNT) AS SUM_EXPN_AMNT,
                SUM(SUM_DSCT_AMNT) AS SUM_DSCT_AMNT,
                SUM(SUM_CASH_AMNT) AS SUM_CASH_AMNT,
                SUM(SUM_POS_AMNT) AS SUM_POS_AMNT,
                SUM(SUM_C2C_AMNT) AS SUM_C2C_AMNT,
                SUM(SUM_DPST_AMNT) AS SUM_DPST_AMNT,
                SUM(SUM_REMN_AMNT) AS SUM_REMN_AMNT
           FROM dbo.Statistic_Detail sd
          WHERE sd.STIS_CODE = @StisCode
            AND sd.SEX_TYPE IN ('001', '002')
            AND sd.SUM_EXPN_AMNT > 0
          GROUP BY sd.STIS_DESC
      ) T;
   	
	   -- 7th * Summery
	   INSERT INTO dbo.Statistic_Detail ( STIS_CODE ,CODE ,STIS_DESC )
	   VALUES  ( @StisCode ,dbo.GNRT_NVID_U() ,N'***** گزارش صندوقداران *****' );
	   
	   -- 8th * Cashier Amount Type Summery	   
	   MERGE dbo.Statistic_Detail T
	   USING (
	      SELECT T.STIS_CODE, T.STIS_DESC, T.RECT_TYPE, 
	             SUM(T.SUM_CASH_AMNT) AS SUM_CASH_AMNT,
	             SUM(T.SUM_POS_AMNT) AS SUM_POS_AMNT,
	             SUM(T.SUM_C2C_AMNT) AS SUM_C2C_AMNT
	        FROM (
	      -- مختص نرم افزار ارتا
	      SELECT @StisCode AS STIS_CODE,
	             u.USER_NAME AS STIS_DESC, 
	             '002' AS RECT_TYPE,
	             ISNULL(SUM(CASE pm.RCPT_MTOD WHEN '001' THEN pm.AMNT ELSE 0 END), 0) AS SUM_CASH_AMNT,
	             ISNULL(SUM(CASE pm.RCPT_MTOD WHEN '003' THEN pm.AMNT ELSE 0 END), 0) AS SUM_POS_AMNT,
	             ISNULL(SUM(CASE pm.RCPT_MTOD WHEN '009' THEN pm.AMNT ELSE 0 END), 0) AS SUM_C2C_AMNT
	        FROM dbo.Payment_Method pm, dbo.V#Users u
	       WHERE CAST(pm.ACTN_DATE AS DATE) = @StisDate
	         AND pm.RCPT_MTOD IN ('001', '003', '009')
	         AND pm.CRET_BY = u.USER_DB
	       GROUP BY u.USER_NAME
	      UNION ALL
	      SELECT @StisCode AS STIS_CODE,
	             u.USER_NAME AS STIS_DESC, 
	             '002' AS RECT_TYPE,
	             ISNULL(SUM(CASE pm.RCPT_MTOD WHEN '001' THEN pm.AMNT ELSE 0 END), 0) AS SUM_CASH_AMNT,
	             ISNULL(SUM(CASE pm.RCPT_MTOD WHEN '003' THEN pm.AMNT ELSE 0 END), 0) AS SUM_POS_AMNT,
	             ISNULL(SUM(CASE pm.RCPT_MTOD WHEN '009' THEN pm.AMNT ELSE 0 END), 0) AS SUM_C2C_AMNT
	        FROM dbo.Gain_Loss_Rail_Detail pm, dbo.Gain_Loss_Rial g, dbo.V#Users u
	       WHERE pm.GLRL_GLID = g.GLID
	         AND g.CONF_STAT = '002'
	         AND g.DPST_STAT = '002'
	         AND CAST(g.PAID_DATE AS DATE) = @StisDate
	         AND pm.RCPT_MTOD IN ('001', '003', '009')
	         AND pm.CRET_BY = u.USER_DB
	       GROUP BY u.USER_NAME
	      UNION ALL
	      SELECT @StisCode AS STIS_CODE,
	             u.USER_NAME AS STIS_DESC, 
	             '002' AS RECT_TYPE,
	             ISNULL(SUM(CASE pm.RCPT_MTOD WHEN '001' THEN pm.AMNT ELSE 0 END), 0) AS SUM_CASH_AMNT,
	             ISNULL(SUM(CASE pm.RCPT_MTOD WHEN '003' THEN pm.AMNT ELSE 0 END), 0) AS SUM_POS_AMNT,
	             ISNULL(SUM(CASE pm.RCPT_MTOD WHEN '009' THEN pm.AMNT ELSE 0 END), 0) AS SUM_C2C_AMNT
	        FROM iRoboTech.dbo.Order_State pm, dbo.V#Users u, iRoboTech.dbo.[Order] o
	       WHERE CAST(pm.STAT_DATE AS DATE) = @StisDate
	         AND pm.ORDR_CODE = o.CODE
	         AND o.ORDR_STAT IN ('004', '009')
	         AND pm.RCPT_MTOD IN ('001', '003', '009')
	         AND pm.AMNT_TYPE = '007'
	         AND u.USER_DB = pm.CRET_BY
	       GROUP BY u.USER_NAME
	       ) T
	       GROUP BY T.STIS_CODE, T.STIS_DESC, T.RECT_TYPE
	   ) S
	   ON (T.STIS_CODE = S.STIS_CODE AND
	       T.STIS_DESC = S.STIS_DESC AND
	       T.RECT_TYPE = S.RECT_TYPE)
	   WHEN NOT MATCHED THEN 
	      INSERT ( STIS_CODE, CODE, STIS_DESC,RECT_TYPE, SUM_EXPN_AMNT, SUM_DSCT_AMNT, SUM_REMN_AMNT, SUM_CASH_AMNT, SUM_POS_AMNT, SUM_C2C_AMNT, SUM_DPST_AMNT, AMNT_TYPE, SEX_TYPE )
	      VALUES ( s.STIS_CODE, dbo.GNRT_NVID_U(), S.STIS_DESC, S.RECT_TYPE, S.SUM_CASH_AMNT + S.SUM_POS_AMNT + S.SUM_C2C_AMNT, 0, 0, s.SUM_CASH_AMNT, s.SUM_POS_AMNT, s.SUM_C2C_AMNT, 0, '001', '003' )
      WHEN MATCHED THEN 
         UPDATE SET             
            T.SUM_EXPN_AMNT += s.SUM_CASH_AMNT + s.SUM_POS_AMNT + s.SUM_C2C_AMNT,
            T.SUM_CASH_AMNT += s.SUM_CASH_AMNT,
            T.SUM_POS_AMNT += S.SUM_POS_AMNT,
            T.SUM_C2C_AMNT += S.SUM_C2C_AMNT;
	   
	   INSERT INTO dbo.Statistic_Detail( STIS_CODE ,CODE ,STIS_DESC , SUM_EXPN_AMNT ,SUM_CASH_AMNT ,SUM_POS_AMNT ,SUM_C2C_AMNT , RECT_TYPE )
	   SELECT @StisCode, dbo.GNRT_NVID_U(), N'***** گزارش جمع کل *****',
	          ISNULL(SUM(sd.SUM_EXPN_AMNT), 0),
	          ISNULL(SUM(sd.SUM_CASH_AMNT), 0),
	          ISNULL(SUM(sd.SUM_POS_AMNT), 0),
	          ISNULL(SUM(sd.SUM_C2C_AMNT), 0),
	          '002'
	     FROM dbo.Statistic_Detail sd
	    WHERE sd.STIS_CODE = @StisCode
	      AND sd.RECT_TYPE = '002';
	   
	   -- علامت گذاری رکورد های خروجی اول
	   UPDATE dbo.Statistic_Detail SET RECT_TYPE = '002' WHERE STIS_CODE = @StisCode AND RECT_TYPE IS NULL;
	      
	   UPDATE dbo.Statistic 
	      SET STIS_STAT = '002'
	    WHERE CODE = @StisCode;
	   
	   L$NextDate:      
	   SET @StisDate = DATEADD(DAY, 1, @StisDate);
	END 
	
	COMMIT TRANSACTION [T$CRET_STIS_P]
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(max) = ERROR_MESSAGE();
	   RAISERROR(@ErorMesg, 16, 1);
	   ROLLBACK TRANSACTION [T$CRET_STIS_P]
	END CATCH
END
GO
