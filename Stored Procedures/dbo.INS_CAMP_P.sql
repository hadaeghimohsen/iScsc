SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_CAMP_P]
	@Rqid BIGINT
  ,@RqroRwno SMALLINT
  ,@FileNo BIGINT
  ,@RectCode VARCHAR(3)
  ,@LevlNumb VARCHAR(3)
  ,@CampDate DATE
  ,@PlacAdrs NVARCHAR(250)
  ,@SectNumb VARCHAR(3)
AS
BEGIN
   INSERT INTO Campitition (RQRO_RQST_RQID, RQRO_RWNO, FIGH_FILE_NO, RECT_CODE, LEVL_NUMB, CAMP_DATE, PLAC_ADRS, SECT_NUMB)
   VALUES (@Rqid, @RqroRwno, @FileNo, @RectCode, @LevlNumb, @CampDate, @PlacAdrs, @SectNumb);
END
GO
