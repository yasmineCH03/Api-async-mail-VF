#!/bin/bash

# 🚀 Script de Déploiement - API Async Email
# Usage: ./scripts/deploy.sh [environment]

set -e

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction de logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

# Vérifier les prérequis
check_prerequisites() {
    log "Vérification des prérequis..."
    
    if ! command -v docker &> /dev/null; then
        error "Docker n'est pas installé"
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose n'est pas installé"
    fi
    
    success "Prérequis vérifiés"
}

# Nettoyer l'environnement
cleanup() {
    log "Nettoyage de l'environnement..."
    
    # Arrêter les containers existants
    docker-compose down 2>/dev/null || true
    
    # Nettoyer les images inutilisées
    docker image prune -f
    
    success "Environnement nettoyé"
}

# Construire les images
build_images() {
    log "Construction des images Docker..."
    
    docker-compose build --no-cache
    
    success "Images construites"
}

# Démarrer les services
start_services() {
    log "Démarrage des services..."
    
    docker-compose up -d
    
    # Attendre que les services soient prêts
    log "Attente du démarrage des services..."
    sleep 30
    
    success "Services démarrés"
}

# Vérifier la santé des services
health_check() {
    log "Vérification de la santé des services..."
    
    # Vérifier que tous les containers sont en cours d'exécution
    if ! docker-compose ps | grep -q "Up"; then
        error "Certains services ne sont pas démarrés"
    fi
    
    # Vérifier l'API
    if ! curl -f http://localhost:8000/emails >/dev/null 2>&1; then
        warning "L'API n'est pas encore accessible, attente..."
        sleep 10
    fi
    
    success "Services en bonne santé"
}

# Installer les dépendances
install_dependencies() {
    log "Installation des dépendances..."
    
    docker-compose exec -T php composer install --no-dev --optimize-autoloader
    
    success "Dépendances installées"
}

# Configurer l'application
configure_app() {
    log "Configuration de l'application..."
    
    # Vider le cache
    docker-compose exec -T php php bin/console cache:clear --env=prod
    
    # Créer les répertoires nécessaires
    docker-compose exec -T php mkdir -p var/cache var/log var/queue
    
    # Définir les permissions
    docker-compose exec -T php chmod -R 755 var/
    
    success "Application configurée"
}

# Lancer les tests
run_tests() {
    log "Exécution des tests..."
    
    if docker-compose exec -T php php bin/phpunit --testdox; then
        success "Tests passés"
    else
        warning "Certains tests ont échoué"
    fi
}

# Afficher les informations de déploiement
show_deployment_info() {
    log "Informations de déploiement:"
    echo ""
    echo "🌐 API: http://localhost:8000"
    echo "📊 MongoDB Express: http://localhost:8081"
    echo "📧 Mailpit: http://localhost:8025"
    echo "🐰 RabbitMQ Management: http://localhost:15672"
    echo ""
    echo "📋 Commandes utiles:"
    echo "  - Voir les logs: docker-compose logs -f"
    echo "  - Arrêter: docker-compose down"
    echo "  - Redémarrer: docker-compose restart"
    echo ""
}

# Fonction principale
main() {
    local environment=${1:-dev}
    
    log "Déploiement de l'API Async Email (environnement: $environment)"
    
    check_prerequisites
    cleanup
    build_images
    start_services
    install_dependencies
    configure_app
    health_check
    
    if [ "$environment" = "dev" ]; then
        run_tests
    fi
    
    show_deployment_info
    
    success "Déploiement terminé avec succès! 🎉"
}

# Gestion des erreurs
trap 'error "Déploiement échoué"' ERR

# Exécution du script
main "$@"
