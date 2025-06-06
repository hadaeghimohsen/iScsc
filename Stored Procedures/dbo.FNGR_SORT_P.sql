SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[FNGR_SORT_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	BEGIN TRY
	BEGIN TRAN [T$FNGR_SORT_P]
	
	-- Local Param
	DECLARE @LastMbspEndDate DATE,
	        @CheckLastMbspEndDate VARCHAR(3),
	        @LastMbspEndDay INT,
	        @CheckLastMbspEndDay VARCHAR(3);
	
	SELECT @LastMbspEndDate = @X.query('//Process').value('(Process/@lastmbspenddate)[1]', 'DATE'),
	       @CheckLastMbspEndDate = @X.query('//Process').value('(Process/@checklastmbspenddate)[1]', 'VARCHAR(3)'),
	       @LastMbspEndDay  = @X.query('//Process').value('(Process/@lastmbspendday)[1]', 'INT'),
	       @CheckLastMbspEndDay = @X.query('//Process').value('(Process/@checklastmbspendday)[1]', 'VARCHAR(3)');
	
	-- Local Vars
	DECLARE @FngrPrnt INT = 1,
	        @FileNo BIGINT;
	
	ALTER TABLE dbo.Fighter_Public DISABLE TRIGGER [CG$AUPD_FGPB];
	ALTER TABLE dbo.Fighter DISABLE TRIGGER [CG$AUPD_FIGH];
	
	UPDATE fp
	   SET fp.FNGR_PRNT = NULL
	  FROM dbo.Fighter_Public fp, dbo.Fighter f
	 WHERE fp.FIGH_FILE_NO = f.FILE_NO
	   AND fp.RWNO = f.FGPB_RWNO_DNRM
	   AND fp.RECT_CODE = '004'
	   AND f.FGPB_TYPE_DNRM != '005';
   
   UPDATE dbo.Fighter
      SET FNGR_PRNT_DNRM = NULL
    WHERE FGPB_TYPE_DNRM != '005';	
	
	DECLARE C$ProcFigh CURSOR FOR
	   SELECT f.FILE_NO
	     FROM dbo.Fighter f, dbo.Member_Ship ms
	    WHERE f.FILE_NO = ms.FIGH_FILE_NO
	      AND f.CONF_STAT = '002'
	      AND f.ACTV_TAG_DNRM = '101'
	      AND f.FGPB_TYPE_DNRM = '001'
	      AND ms.RWNO = (SELECT MAX(ms1.RWNO) FROM dbo.Member_Ship ms1 WHERE ms.FIGH_FILE_NO = ms1.FIGH_FILE_NO AND ms.RECT_CODE = ms1.RECT_CODE AND ms.VALD_TYPE = ms1.VALD_TYPE)
	      AND ms.RECT_CODE = '004'
	      AND ms.VALD_TYPE = '002'	      
	      AND (
	          @CheckLastMbspEndDate = '002' AND (ms.END_DATE >= @LastMbspEndDate)
	          OR
	          @CheckLastMbspEndDay  = '002' AND (ABS(DATEDIFF(DAY, GETDATE(), ms.END_DATE)) <= @LastMbspEndDay)
	      )
	   UNION ALL
	   SELECT f.FILE_NO
	     FROM fighter f
	    WHERE f.FGPB_TYPE_DNRM = '003'
	      AND f.CONF_STAT = '002'
	      AND f.ACTV_TAG_DNRM = '101'
	    ORDER BY f.FILE_NO;
	
	OPEN [C$ProcFigh];
	L$Loop:
	FETCH [C$ProcFigh] INTO @FileNo;
	
	IF @@FETCH_STATUS <> 0
	   GOTO L$EndLoop;
	
	UPDATE fp
	   SET fp.FNGR_PRNT = @FngrPrnt
	  FROM dbo.Fighter_Public fp, dbo.Fighter f
	 WHERE fp.FIGH_FILE_NO = f.FILE_NO
	   AND fp.RWNO = f.FGPB_RWNO_DNRM
	   AND fp.RECT_CODE = '004'
	   AND f.FILE_NO = @FileNo;
	
	UPDATE dbo.Fighter
	   SET FNGR_PRNT_DNRM = @FngrPrnt
	 WHERE FILE_NO = @FileNo;
	
	SET @FngrPrnt += 1;
	
	GOTO L$Loop;
	L$EndLoop:	
	CLOSE [C$ProcFigh];
	DEALLOCATE [C$ProcFigh];
	
	ALTER TABLE dbo.Fighter_Public ENABLE TRIGGER [CG$AUPD_FGPB];
	ALTER TABLE dbo.Fighter ENABLE TRIGGER [CG$AUPD_FIGH];
	
	COMMIT TRAN [T$FNGR_SORT_P]
	END TRY
	BEGIN CATCH	
	DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
   RAISERROR ( @ErorMesg, -- Message text.
            16, -- Severity.
            1 -- State.
            );
   ROLLBACK TRAN [T$FNGR_SORT_P];
	END CATCH
END
GO
