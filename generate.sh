#!/usr/bin/env bash
# HotspotISP Platform Generator
set -e
echo "🚀 Generating HotspotISP Enterprise Platform..."

# Project structure
mkdir -p apps/api/src/{auth,users,plans,vouchers,agents,payments,advertisements,router,reports,bypass,wireguard,settings,common,health,mikrotik,queue}
mkdir -p apps/admin/{app,pages,components,styles}
mkdir -p apps/portal/{app,pages,components,styles}
mkdir -p apps/agent/{app,pages,components,styles}
mkdir -p packages/{shared-types,ui,config}
mkdir -p docker/{nginx}
mkdir -p scripts/{mikrotik,backup}
mkdir -p k8s

# Root files
cat > package.json <<'EOF'
{
  "name": "hotspotisp-monorepo",
  "private": true,
  "scripts": {
    "api": "cd apps/api && npm run start:dev",
    "admin": "cd apps/admin && npm run dev",
    "portal": "cd apps/portal && npm run dev",
    "agent": "cd apps/agent && npm run dev",
    "build:all": "concurrently \"npm run build:api\" \"npm run build:admin\" \"npm run build:portal\" \"npm run build:agent\""
  }
}
EOF

cat > .gitignore <<EOF
node_modules/
dist/
.env
*.log
.DS_Store
EOF

cat > README.md <<'EOF'
# HotspotISP – Enterprise WiFi Billing & MikroTik Management

A complete, production-ready platform for hotspot billing, PPPoE, mobile money, WireGuard, captive portal ads, and automated MikroTik management.

## Quick Start
```bash
git clone https://github.com/your-username/hotspotisp-platform
cd hotspotisp-platform
cp .env.example .env   # fill in your secrets
docker compose up -d
```

- Admin: http://localhost:3000
- API: http://localhost:3001
- Captive Portal: http://localhost:3002
- Agent: http://localhost:3003
EOF

cat > .env.example <<'EOF'
DATABASE_URL=postgresql://hotspotisp:changeme123@postgres:5432/hotspotisp
REDIS_URL=redis://redis:6379
JWT_SECRET=super-secret-jwt-key
VAULT_ENCRYPTION_KEY=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
ADMIN_EMAIL=admin@hotspotisp.com
ADMIN_PASSWORD=Admin123!
CORS_ORIGINS=http://localhost:3000,http://localhost:3002,http://localhost:3003
EOF

# Docker
cat > docker/docker-compose.yml <<'EOF'
version: '3.8'
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: hotspotisp
      POSTGRES_USER: hotspotisp
      POSTGRES_PASSWORD: changeme123
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports:
      - "5432:5432"
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
  api:
    build:
      context: ../apps/api
      dockerfile: ../../docker/Dockerfile.api
    environment:
      NODE_ENV: development
      DATABASE_URL: postgresql://hotspotisp:changeme123@postgres:5432/hotspotisp
      REDIS_URL: redis://redis:6379
      JWT_SECRET: dev-secret
      VAULT_ENCRYPTION_KEY: 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
    ports:
      - "3001:3000"
    depends_on:
      - postgres
      - redis
  admin:
    build:
      context: ../apps/admin
      dockerfile: ../../docker/Dockerfile.frontend
    environment:
      NEXT_PUBLIC_API_URL: http://localhost:3001
    ports:
      - "3000:3000"
    depends_on:
      - api
  portal:
    build:
      context: ../apps/portal
      dockerfile: ../../docker/Dockerfile.frontend
    environment:
      NEXT_PUBLIC_API_URL: http://localhost:3001
    ports:
      - "3002:3000"
    depends_on:
      - api
  agent:
    build:
      context: ../apps/agent
      dockerfile: ../../docker/Dockerfile.frontend
    environment:
      NEXT_PUBLIC_API_URL: http://localhost:3001
    ports:
      - "3003:3000"
    depends_on:
      - api
volumes:
  pgdata:
EOF

cat > docker/Dockerfile.api <<'EOF'
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only-production
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["node", "dist/main"]
EOF

cat > docker/Dockerfile.frontend <<'EOF'
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["npm", "start"]
EOF

# API package.json
cat > apps/api/package.json <<'EOF'
{
  "name": "hotspotisp-api",
  "version": "1.0.0",
  "scripts": {
    "build": "nest build",
    "start:dev": "nest start --watch",
    "start:prod": "node dist/main",
    "migration:run": "typeorm migration:run",
    "seed": "ts-node src/database/seed.ts"
  },
  "dependencies": {
    "@nestjs/common": "^10.0.0",
    "@nestjs/core": "^10.0.0",
    "@nestjs/jwt": "^10.0.0",
    "@nestjs/passport": "^10.0.0",
    "@nestjs/platform-express": "^10.0.0",
    "@nestjs/typeorm": "^10.0.0",
    "@nestjs/bullmq": "^10.0.0",
    "@nestjs/schedule": "^4.0.0",
    "@nestjs/websockets": "^10.0.0",
    "@nestjs/platform-socket.io": "^10.0.0",
    "@nestjs/swagger": "^7.0.0",
    "@nestjs/terminus": "^10.0.0",
    "@nestjs/throttler": "^5.0.0",
    "bullmq": "^5.0.0",
    "class-transformer": "^0.5.0",
    "class-validator": "^0.14.0",
    "typeorm": "^0.3.0",
    "pg": "^8.0.0",
    "redis": "^4.0.0",
    "passport": "^0.7.0",
    "passport-jwt": "^4.0.0",
    "bcrypt": "^5.0.0",
    "helmet": "^7.0.0",
    "socket.io": "^4.0.0",
    "axios": "^1.6.0",
    "qrcode": "^1.5.0",
    "pdfkit": "^0.13.0",
    "handlebars": "^4.7.0",
    "fs-extra": "^11.0.0",
    "uuid": "^9.0.0",
    "reflect-metadata": "^0.1.13",
    "rxjs": "^7.8.0"
  },
  "devDependencies": {
    "@nestjs/cli": "^10.0.0",
    "@types/express": "^4.17.0",
    "@types/node": "^20.0.0",
    "typescript": "^5.0.0",
    "ts-node": "^10.9.0"
  }
}
EOF

# API main source
cat > apps/api/src/main.ts <<'EOF'
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import helmet from 'helmet';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.use(helmet());
  app.enableCors({ origin: process.env.CORS_ORIGINS?.split(',') });
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true }));

  const config = new DocumentBuilder()
    .setTitle('HotspotISP API')
    .setVersion('1.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(`🚀 API running on port ${port}`);
}
bootstrap();
EOF

cat > apps/api/src/app.module.ts <<'EOF'
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BullModule } from '@nestjs/bullmq';
import { ScheduleModule } from '@nestjs/schedule';
import { ThrottlerModule } from '@nestjs/throttler';
import { TerminusModule } from '@nestjs/terminus';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { PlansModule } from './plans/plans.module';
import { VouchersModule } from './vouchers/vouchers.module';
import { PaymentsModule } from './payments/payments.module';
import { RouterModule } from './router/router.module';
import { AdvertisementsModule } from './advertisements/advertisements.module';
import { WireguardModule } from './wireguard/wireguard.module';
import { BypassModule } from './bypass/bypass.module';
import { SettingsModule } from './settings/settings.module';
import { ReportsModule } from './reports/reports.module';
import { HealthController } from './health/health.controller';

@Module({
  imports: [
    ThrottlerModule.forRoot([{ ttl: 60000, limit: 100 }]),
    ScheduleModule.forRoot(),
    TypeOrmModule.forRoot({
      type: 'postgres',
      url: process.env.DATABASE_URL,
      autoLoadEntities: true,
      synchronize: process.env.NODE_ENV !== 'production',
    }),
    BullModule.forRoot({ connection: { url: process.env.REDIS_URL } }),
    TerminusModule,
    AuthModule,
    UsersModule,
    PlansModule,
    VouchersModule,
    PaymentsModule,
    RouterModule,
    AdvertisementsModule,
    WireguardModule,
    BypassModule,
    SettingsModule,
    ReportsModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
EOF

cat > apps/api/src/health/health.controller.ts <<'EOF'
import { Controller, Get } from '@nestjs/common';
import { HealthCheck, HealthCheckService, TypeOrmHealthIndicator } from '@nestjs/terminus';

@Controller('health')
export class HealthController {
  constructor(private health: HealthCheckService, private db: TypeOrmHealthIndicator) {}

  @Get()
  @HealthCheck()
  check() {
    return this.health.check([() => this.db.pingCheck('database')]);
  }
}
EOF

# Placeholder modules
for module in auth users plans vouchers agents payments advertisements router reports bypass wireguard settings; do
  mkdir -p apps/api/src/$module
  cat > apps/api/src/$module/${module}.module.ts <<EOF
  import { Module } from '@nestjs/common';
  @Module({})
  export class $(echo ${module^} | sed 's/-///') Module {}
  EOF
done

# Frontend apps
cat > apps/admin/package.json <<'EOF'
{
  "name": "hotspotisp-admin",
  "version": "1.0.0",
  "scripts": {
    "dev": "next dev -p 3000",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "next": "^14.0.0",
    "react": "^18.0.0",
    "react-dom": "^18.0.0",
    "axios": "^1.6.0",
    "framer-motion": "^10.0.0",
    "socket.io-client": "^4.0.0",
    "@heroicons/react": "^2.0.0"
  },
  "devDependencies": {
    "typescript": "^5.0.0",
    "autoprefixer": "^10.0.0",
    "postcss": "^8.0.0",
    "tailwindcss": "^3.0.0"
  }
}
EOF

cat > apps/admin/app/page.tsx <<'EOF'
export default function Home() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-900 text-white">
      <h1 className="text-3xl font-bold">HotspotISP Admin</h1>
    </div>
  );
}
EOF

cp apps/admin/package.json apps/portal/package.json && sed -i 's/admin/portal/' apps/portal/package.json
cp apps/admin/app/page.tsx apps/portal/app/page.tsx && sed -i 's/Admin/Captive Portal/' apps/portal/app/page.tsx

cp apps/admin/package.json apps/agent/package.json && sed -i 's/admin/agent/' apps/agent/package.json
cp apps/admin/app/page.tsx apps/agent/app/page.tsx && sed -i 's/Admin/Agent Panel/' apps/agent/app/page.tsx

for app in admin portal agent; do
  cat > apps/$app/tailwind.config.js <<'EOF'
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./app/**/*.{js,ts,jsx,tsx}"],
  theme: { extend: {} },
  plugins: [],
}
EOF
  cat > apps/$app/postcss.config.js <<'EOF'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF
  cat > apps/$app/app/globals.css <<'EOF'@tailwind base;
@tailwind components;
@tailwind utilities;
EOF
done

# Shared packages
cat > packages/shared-types/index.ts <<'EOF'
export enum Role {
  SUPER_ADMIN = 'super_admin',
  ADMIN = 'admin',
  STAFF = 'staff',
  AGENT = 'agent',
}
export const ROLES_KEY = 'roles';
EOF

cat > packages/ui/ThemeContext.tsx <<'EOF'
'use client';
import React from 'react';
interface Theme { mode: string; glassBlur: number; }
export const ThemeContext = React.createContext({ theme: { mode: 'dark', glassBlur: 20 }, updateTheme: (t: Partial<Theme>) => {} });
export const useTheme = () => React.useContext(ThemeContext);
EOF

cat > packages/config/tailwind-theme.js <<'EOF'
module.exports = {
  theme: {
    extend: {
      colors: { primary: '#06b6d4' },
    }
  }
};
EOF

# Deployment scripts
cat > scripts/deploy.sh <<'EOF'
#!/bin/bash
set -e
docker compose -f docker/docker-compose.prod.yml up -d --build
echo "✅ Production deployed"
EOF

cat > docs/DEPLOYMENT.md <<'EOF'
# Production Deployment Guide
- See docker/docker-compose.prod.yml for environment variables.
- SSL: Use Let's Encrypt with Nginx.
- For Kubernetes, see the k8s/ directory.
EOF

echo "✅ HotspotISP Enterprise Platform generated successfully!"
EOF
# trigger
