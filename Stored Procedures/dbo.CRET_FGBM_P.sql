SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CRET_FGBM_P]
	-- Add the parameters for the stored procedure here
	@FileNo BIGINT
AS
BEGIN
	MERGE dbo.Fighter_Body_Measurement T
	USING (SELECT @FileNo AS FILE_NO, VALU AS BODY_TYPE FROM dbo.[D$BODY]) S
	ON (T.FIGH_FILE_NO = S.FILE_NO AND 
	    T.BODY_TYPE = S.BODY_TYPE)
	WHEN NOT MATCHED THEN 
	   INSERT (FIGH_FILE_NO, BODY_TYPE, CODE, MESR_VALU)
	   VALUES (S.FILE_NO, S.BODY_TYPE, dbo.GNRT_NVID_U(), 0);
END
GO
