SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[VF$AL$Fighter]
AS
SELECT  TOP (100) PERCENT dbo.Fighter.FILE_NO, dbo.Fighter_Public.RWNO, dbo.Fighter_Public.NATL_CODE, dbo.Fighter_Public.GLOB_CODE, dbo.Fighter_Public.POST_ADRS, dbo.Fighter_Public.EMAL_ADRS, 
               dbo.Fighter_Public.BRTH_DATE, dbo.Fighter_Public.CELL_PHON, dbo.Fighter_Public.TELL_PHON, dbo.Fighter_Public.COCH_DEG, dbo.Fighter_Public.GUDG_DEG, dbo.Fighter_Public.TYPE, 
               dbo.Fighter_Public.INSR_NUMB, dbo.Fighter_Public.INSR_DATE, dbo.Fighter_Public.FATH_NAME, dbo.Fighter_Public.LAST_NAME, dbo.Fighter_Public.FRST_NAME, dbo.Diseases_Type.DISE_DESC, 
               dbo.Method.MTOD_DESC, dbo.Category_Belt.CTGY_DESC, dbo.Club.NAME AS CLUB_NAME, dbo.D$FGTP.DOMN_DESC AS TYPE_DESC, dbo.D$DEGR.DOMN_DESC AS COCH_DEGR, 
               D$DEGR_1.DOMN_DESC AS GUGD_DEGR, dbo.D$SXTP.DOMN_DESC AS SEX_TYPE, dbo.Fighter_Public.FNGR_PRNT
FROM     dbo.Category_Belt INNER JOIN
               dbo.Method ON dbo.Category_Belt.MTOD_CODE = dbo.Method.CODE INNER JOIN
               dbo.Fighter INNER JOIN
               dbo.Fighter_Public ON dbo.Fighter.FILE_NO = dbo.Fighter_Public.FIGH_FILE_NO INNER JOIN
               dbo.Club ON dbo.Fighter_Public.CLUB_CODE = dbo.Club.CODE INNER JOIN
               dbo.Diseases_Type ON dbo.Fighter_Public.DISE_CODE = dbo.Diseases_Type.CODE INNER JOIN
               dbo.D$FGTP ON dbo.Fighter_Public.TYPE = dbo.D$FGTP.VALU INNER JOIN
               dbo.D$SXTP ON dbo.Fighter_Public.SEX_TYPE = dbo.D$SXTP.VALU ON dbo.Method.CODE = dbo.Fighter_Public.MTOD_CODE AND dbo.Category_Belt.CODE = dbo.Fighter_Public.CTGY_CODE LEFT OUTER JOIN
               dbo.D$DEGR AS D$DEGR_1 ON dbo.Fighter_Public.GUDG_DEG = D$DEGR_1.VALU LEFT OUTER JOIN
               dbo.D$DEGR ON dbo.Fighter_Public.COCH_DEG = dbo.D$DEGR.VALU
WHERE  (dbo.Fighter_Public.RECT_CODE = '004') AND (dbo.Fighter.CONF_STAT = '002')
ORDER BY dbo.Fighter.FILE_NO, dbo.Fighter_Public.RWNO
GO
EXEC sp_addextendedproperty N'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1[50] 4[8] 3) )"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1[75] 4) )"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 1
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Category_Belt"
            Begin Extent = 
               Top = 404
               Left = 724
               Bottom = 524
               Right = 884
            End
            DisplayFlags = 344
            TopColumn = 0
         End
         Begin Table = "Method"
            Begin Extent = 
               Top = 444
               Left = 505
               Bottom = 564
               Right = 665
            End
            DisplayFlags = 344
            TopColumn = 0
         End
         Begin Table = "Fighter"
            Begin Extent = 
               Top = 12
               Left = 7
               Bottom = 321
               Right = 221
            End
            DisplayFlags = 344
            TopColumn = 0
         End
         Begin Table = "Fighter_Public"
            Begin Extent = 
               Top = 165
               Left = 323
               Bottom = 391
               Right = 537
            End
            DisplayFlags = 280
            TopColumn = 32
         End
         Begin Table = "Club"
            Begin Extent = 
               Top = 414
               Left = 20
               Bottom = 534
               Right = 234
            End
            DisplayFlags = 344
            TopColumn = 0
         End
         Begin Table = "Diseases_Type"
            Begin Extent = 
               Top = 4
               Left = 663
               Bottom = 124
               Right = 823
            End
            DisplayFlags = 344
            TopColumn = 0
         End
         Begin Table = "D$FGTP"
            Begin Extent = 
               Top = 50
               Left = 666
               Bottom = 140
               Right = 826
            End
            Displa', 'SCHEMA', N'dbo', 'VIEW', N'VF$AL$Fighter', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_DiagramPane2', N'yFlags = 344
            TopColumn = 0
         End
         Begin Table = "D$SXTP"
            Begin Extent = 
               Top = 99
               Left = 667
               Bottom = 189
               Right = 827
            End
            DisplayFlags = 344
            TopColumn = 0
         End
         Begin Table = "D$DEGR_1"
            Begin Extent = 
               Top = 294
               Left = 673
               Bottom = 384
               Right = 833
            End
            DisplayFlags = 344
            TopColumn = 0
         End
         Begin Table = "D$DEGR"
            Begin Extent = 
               Top = 248
               Left = 673
               Bottom = 338
               Right = 833
            End
            DisplayFlags = 344
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
      PaneHidden = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 28
         Width = 284
         Width = 1650
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1305
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
', 'SCHEMA', N'dbo', 'VIEW', N'VF$AL$Fighter', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=2
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'VF$AL$Fighter', NULL, NULL
GO
