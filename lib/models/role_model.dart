/// Enum de papéis do usuário alinhado com o backend.
/// Inclui papéis usados no frontend que podem precisar de alinhamento com o backend.
enum Role {
  admMaster,         // Backend: "ADM" (Superusuário, engloba adminReivindicado e federationAdmin)
  leader,      // Backend: "Leader" (Corresponde a Leader de Clã/Federação no backend)
  subLeader,   // Backend: "SubLeader" (Corresponde a SubLeader de Clã/Federação no backend)
  member,      // Backend: "Member" (Corresponde a Member de Clã/Federação no backend)
  user,        // Backend: "User" (Papel padrão para usuários registrados sem função específica)
  idcloned,          // Adicionado: Papel específico para o ADM Master idcloned
  federationLeader,  // Adicionado: Papel de Líder de Federação
  clanLeader,      // Usado no frontend. No backend, o papel é "Leader".
  clanSubLeader,   // Usado no frontend. No backend, o papel é "SubLeader".
  clanMember,      // Usado no frontend. No backend, o papel é "Member".
  guest,           // Usado no frontend para usuários não autenticados ou com papel indefinido. Sem correspondência direta no backend.
}

extension RoleExtension on Role {
  String get displayName {
    switch (this) {
      case Role.admMaster: return 'ADM Master'; // Nome de exibição para o superusuário
      case Role.leader: return 'Líder';
      case Role.subLeader: return 'Sub-Líder';
      case Role.member: return 'Membro';
      case Role.user: return 'Usuário';
      case Role.clanLeader: return 'Líder de Clã';
      case Role.clanSubLeader: return 'Sub-Líder de Clã';
      case Role.clanMember: return 'Membro de Clã';
      case Role.guest: return 'Convidado';
      case Role.idcloned: return 'ID Cloned Master';
      case Role.federationLeader: return 'Líder de Federação';
    }
  }
}

/// Converte string do backend para enum Role.
/// ATENÇÃO: Sempre alinhe os valores aqui com o backend!
/// Exemplo de uso: Role userRole = roleFromString(json["role"]);
Role roleFromString(String? roleString) {
  switch (roleString) {
    case 'ADM':
    case 'adminReivindicado':
    case 'federationAdmin':
      return Role.admMaster;
    case 'Leader':
      return Role.leader;
    case 'SubLeader':
      return Role.subLeader;
    case 'Member':
      return Role.member;
    case 'User':
      return Role.user;
    case 'idcloned':
      return Role.idcloned;
    case 'federationLeader':
      return Role.federationLeader;
    case 'clanLeader':
      return Role.clanLeader;
    case 'clanSubLeader':
      return Role.clanSubLeader;
    case 'clanMember':
      return Role.clanMember;
    case 'guest':
      return Role.guest;
    default:
      return Role.user; // Valor padrão seguro
  }
}

/// Converte enum Role para string do backend.
/// Deve retornar os valores string exatos que o backend espera.
/// Exemplo de uso: String roleStr = roleToString(user.role);
String roleToString(Role role) {
  switch (role) {
    case Role.admMaster:
      return 'ADM'; // O ADM Master no frontend corresponde a 'ADM' no backend
    case Role.leader:
      return 'Leader';
    case Role.subLeader:
      return 'SubLeader';
    case Role.member:
      return 'Member';
    case Role.user:
      return 'User';
    case Role.idcloned:
      return 'idcloned';
    case Role.federationLeader:
      return 'federationLeader';
    case Role.clanLeader:
       return 'Leader'; // Mapeia papel de frontend para string de backend clanRole/federationRole
    case Role.clanSubLeader:
       return 'SubLeader'; // Mapeia papel de frontend para string de backend clanRole/federationRole
    case Role.clanMember:
       return 'Member'; // Mapeia papel de frontend para string de backend clanRole/federationRole
    case Role.guest:
       return 'User'; // Mapeia Convidado para User no backend se for o campo 'role' global
  }
}

/// ANOTAÇÕES PARA O BACKEND:
/// - Sempre alinhe o enum e as funções helpers com o backend para evitar bugs de permissão e navegação.

/// EXEMPLO DE USO NO MODELO:
/// 

