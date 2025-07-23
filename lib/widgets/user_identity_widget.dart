import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserIdentityWidget extends StatelessWidget {
  final String userId;
  final String username;
  final String? avatar;
  final String? clanFlag;
  final String? federationTag;
  final String? role;
  final String? clanRole;
  final bool isOnline; // Adicionado para status online/offline
  final double size;
  final bool showFullIdentity;
  final TextStyle? textStyle;
  final bool isClickable;
  final VoidCallback? onTap;

  const UserIdentityWidget({
    super.key,
    required this.userId,
    required this.username,
    this.avatar,
    this.clanFlag,
    this.federationTag,
    this.role,
    this.clanRole,
    this.isOnline = false, // Valor padrão
    this.size = 40.0,
    this.showFullIdentity = true,
    this.textStyle,
    this.isClickable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Foto de perfil
        _buildProfilePicture(),
        
        if (showFullIdentity) ...[
          const SizedBox(width: 8),
          
          // Bandeira do clã (se existir)
          if (clanFlag != null && clanFlag!.isNotEmpty) ...[
            _buildClanFlag(),
            const SizedBox(width: 6),
          ],
          
          // Nome do usuário com role badge
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nome do usuário
                    Flexible(
                      child: Text(
                        username,
                        style: textStyle ?? const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // TAG da federação (se existir)
                    if (federationTag != null && federationTag!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _buildFederationTag(),
                    ],
                  ],
                ),
                
                // Role badges (se existir)
                if (_shouldShowRoleBadges()) ...[
                  const SizedBox(height: 2),
                  _buildRoleBadges(),
                ],
              ],
            ),
          ),
        ],
      ],
    );

    if (isClickable && onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }

  Widget _buildProfilePicture() {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _getRoleBorderColor(),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: avatar != null && avatar!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: avatar!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.person,
                        color: Colors.grey,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.person,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : Container(
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.person,
                      color: Colors.grey,
                    ),
                  ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: size * 0.25,
            height: size * 0.25,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.red,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.black,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClanFlag() {
    return Container(
      width: size * 0.8,
      height: size * 0.5,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[600]!, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: CachedNetworkImage(
          imageUrl: clanFlag!,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[800],
            child: const Icon(
              Icons.flag,
              color: Colors.grey,
              size: 12,
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[800],
            child: const Icon(
              Icons.flag,
              color: Colors.grey,
              size: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFederationTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[300]!, width: 1),
      ),
      child: Text(
        '[$federationTag]',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  bool _shouldShowRoleBadges() {
    return (role != null && role != 'member') || 
           (clanRole != null && clanRole != 'member');
  }

  Widget _buildRoleBadges() {
    List<Widget> badges = [];

    // Badge do role global
    if (role != null && role != 'member') {
      badges.add(_buildRoleBadge(role!, _getGlobalRoleColor(role!)));
    }

    // Badge do role do clã
    if (clanRole != null && clanRole != 'member') {
      badges.add(_buildRoleBadge(_getClanRoleDisplayName(clanRole!), _getClanRoleColor(clanRole!)));
    }

    return Wrap(
      spacing: 4,
      children: badges,
    );
  }

  Widget _buildRoleBadge(String roleText, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withAlpha((0.2 * 255).round()),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        roleText,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 8,
        ),
      ),
    );
  }

  Color _getRoleBorderColor() {
    if (role == 'ADM') return Colors.red;
    if (clanRole == 'leader') return Colors.orange;
    if (clanRole == 'sub_leader') return Colors.yellow;
    return Colors.grey[600]!;
  }

  Color _getGlobalRoleColor(String globalRole) {
    switch (globalRole) {
      case 'ADM':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getClanRoleColor(String clanRoleValue) {
    switch (clanRoleValue) {
      case 'leader':
        return Colors.orange;
      case 'sub_leader':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  String _getClanRoleDisplayName(String clanRoleValue) {
    switch (clanRoleValue) {
      case 'leader':
        return 'LÍDER';
      case 'sub_leader':
        return 'SUB-LÍDER';
      default:
        return clanRoleValue.toUpperCase();
    }
  }
}

// Widget simplificado para uso em listas
class SimpleUserIdentityWidget extends StatelessWidget {
  final String username;
  final String? avatar;
  final String? clanFlag;
  final String? federationTag;
  final double size;

  const SimpleUserIdentityWidget({
    super.key, // Esta linha permanece
    required this.username,
    this.avatar,
    this.clanFlag,
    this.federationTag,
    this.size = 32.0,
  }); // A linha ": super(key: key);" foi removida daqui.

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Foto de perfil
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[600]!, width: 1),
          ),
          child: ClipOval(
            child: avatar != null && avatar!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: avatar!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.person, color: Colors.grey, size: 16),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.person, color: Colors.grey, size: 16),
                    ),
                  )
                : Container(
                    color: Colors.grey[800],
                    child: const Icon(Icons.person, color: Colors.grey, size: 16),
                  ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Bandeira do clã (se existir)
        if (clanFlag != null && clanFlag!.isNotEmpty) ...[
          Container(
            width: size * 0.7,
            height: size * 0.4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.grey[600]!, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: CachedNetworkImage(
                imageUrl: clanFlag!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.flag, color: Colors.grey, size: 10),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.flag, color: Colors.grey, size: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        
        // Nome e TAG
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // TAG da federação (se existir)
              if (federationTag != null && federationTag!.isNotEmpty) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '[$federationTag]',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 8,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
