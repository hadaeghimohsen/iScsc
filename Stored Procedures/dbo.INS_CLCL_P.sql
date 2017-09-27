SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_CLCL_P]
	@Rqid BIGINT
  ,@RqroRwno SMALLINT
  ,@FileNo BIGINT
  ,@RectCode VARCHAR(3)
  ,@Hegh REAL
  ,@Wegh SMALLINT
  ,@TranTime INT
AS
BEGIN
   INSERT INTO Calculate_Calorie(RQRO_RQST_RQID, RQRO_RWNO, FIGH_FILE_NO, RECT_CODE, HEGH, WEGH, TRAN_TIME)
   VALUES (@Rqid, @RqroRwno, @FileNo, @RectCode, @Hegh, @Wegh, @TranTime);
END
GO
