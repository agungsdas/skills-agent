# App Shell — Sidebar + Header + RBAC Nav

Shell dashboard pakai shadcn **Sidebar** (collapsible, responsive, a11y bawaan) + header dengan breadcrumb, mode toggle, dan user menu.
Navigasi **RBAC-aware**: item difilter berdasarkan role sesi.

Butuh: `pnpm dlx shadcn@latest add sidebar breadcrumb separator avatar dropdown-menu`

---

## 1. Layout terproteksi (Server Component + guard)

```tsx
// src/app/(app)/layout.tsx
import { redirect } from "next/navigation";
import { getSession } from "@/lib/auth/session";
import { SidebarInset, SidebarProvider } from "@/components/ui/sidebar";
import { AppSidebar } from "@/components/layout/app-sidebar";
import { AppHeader } from "@/components/layout/app-header";
import { getNavForRole } from "@/lib/nav";

export default async function AppLayout({ children }: { children: React.ReactNode }) {
  const session = await getSession();
  if (!session) redirect("/login");

  const nav = getNavForRole(session.role); // RBAC: filter menu

  return (
    <SidebarProvider>
      <AppSidebar nav={nav} user={session} />
      <SidebarInset>
        <AppHeader user={session} />
        <main className="flex-1 p-4 md:p-6">{children}</main>
      </SidebarInset>
    </SidebarProvider>
  );
}
```

---

## 2. Definisi nav + filter RBAC

```ts
// src/lib/nav.ts
import { LayoutDashboard, Users, Settings, BarChart3, type LucideIcon } from "lucide-react";
import type { Role } from "@/lib/auth/session";

export interface NavItem {
  title: string;
  href: string;
  icon: LucideIcon;
  roles?: Role[]; // undefined = semua role
}

const NAV: NavItem[] = [
  { title: "Dashboard", href: "/dashboard", icon: LayoutDashboard },
  { title: "Analitik", href: "/analytics", icon: BarChart3, roles: ["admin", "manager"] },
  { title: "User", href: "/users", icon: Users, roles: ["admin"] },
  { title: "Pengaturan", href: "/settings", icon: Settings },
];

export function getNavForRole(role: Role): NavItem[] {
  return NAV.filter((item) => !item.roles || item.roles.includes(role));
}
```

> Filter nav di server = UX (sembunyikan yang tak relevan). **Keamanan tetap** di route/page guard (`requireAuth` / `getSession` + cek role). Jangan andalkan nav saja.

---

## 3. AppSidebar

```tsx
// src/components/layout/app-sidebar.tsx
"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  Sidebar, SidebarContent, SidebarFooter, SidebarGroup, SidebarGroupLabel,
  SidebarHeader, SidebarMenu, SidebarMenuButton, SidebarMenuItem, SidebarRail,
} from "@/components/ui/sidebar";
import type { NavItem } from "@/lib/nav";
import type { SessionUser } from "@/lib/auth/session";
import { UserMenu } from "./user-menu";

export function AppSidebar({ nav, user }: { nav: NavItem[]; user: SessionUser }) {
  const pathname = usePathname();

  return (
    <Sidebar collapsible="icon">
      <SidebarHeader>
        <div className="flex items-center gap-2 px-2 py-1.5">
          <div className="flex size-8 items-center justify-center rounded-lg bg-primary text-primary-foreground">
            <span className="text-sm font-semibold">M</span>
          </div>
          <span className="font-semibold group-data-[collapsible=icon]:hidden">MyApp</span>
        </div>
      </SidebarHeader>

      <SidebarContent>
        <SidebarGroup>
          <SidebarGroupLabel>Menu</SidebarGroupLabel>
          <SidebarMenu>
            {nav.map((item) => {
              const active = pathname === item.href || pathname.startsWith(`${item.href}/`);
              return (
                <SidebarMenuItem key={item.href}>
                  <SidebarMenuButton asChild isActive={active} tooltip={item.title}>
                    <Link href={item.href}>
                      <item.icon />
                      <span>{item.title}</span>
                    </Link>
                  </SidebarMenuButton>
                </SidebarMenuItem>
              );
            })}
          </SidebarMenu>
        </SidebarGroup>
      </SidebarContent>

      <SidebarFooter>
        <UserMenu user={user} />
      </SidebarFooter>
      <SidebarRail />
    </Sidebar>
  );
}
```

---

## 4. Header (trigger + breadcrumb + mode toggle)

```tsx
// src/components/layout/app-header.tsx
"use client";

import { Separator } from "@/components/ui/separator";
import { SidebarTrigger } from "@/components/ui/sidebar";
import { ModeToggle } from "@/components/commons/mode-toggle";
import { DynamicBreadcrumb } from "./dynamic-breadcrumb";
import type { SessionUser } from "@/lib/auth/session";

export function AppHeader({ user }: { user: SessionUser }) {
  return (
    <header className="sticky top-0 z-10 flex h-14 items-center gap-2 border-b bg-background/95 px-4 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <SidebarTrigger className="-ml-1" />
      <Separator orientation="vertical" className="mr-2 h-4" />
      <DynamicBreadcrumb />
      <div className="ml-auto flex items-center gap-2">
        <ModeToggle />
      </div>
    </header>
  );
}
```

> `bg-background/95 backdrop-blur` = header sticky yang halus (bukan glassmorphism berlebihan). `ModeToggle` dari `nextjs-core/setup.md`.

---

## 5. User menu (logout)

```tsx
// src/components/layout/user-menu.tsx
"use client";

import { useRouter } from "next/navigation";
import { LogOut } from "lucide-react";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import {
  DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuLabel,
  DropdownMenuSeparator, DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { SidebarMenuButton } from "@/components/ui/sidebar";
import type { SessionUser } from "@/lib/auth/session";

export function UserMenu({ user }: { user: SessionUser }) {
  const router = useRouter();

  async function logout() {
    await fetch("/api/auth/logout", { method: "POST" });
    router.push("/login");
    router.refresh();
  }

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <SidebarMenuButton size="lg">
          <Avatar className="size-8">
            <AvatarFallback>{user.email[0]?.toUpperCase()}</AvatarFallback>
          </Avatar>
          <span className="truncate group-data-[collapsible=icon]:hidden">{user.email}</span>
        </SidebarMenuButton>
      </DropdownMenuTrigger>
      <DropdownMenuContent side="top" align="start" className="w-56">
        <DropdownMenuLabel className="capitalize">{user.role}</DropdownMenuLabel>
        <DropdownMenuSeparator />
        <DropdownMenuItem variant="destructive" onClick={logout}>
          <LogOut className="size-4" /> Keluar
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
```

---

## Checklist app shell (wajib)

- [ ] Layout `(app)` di-guard di server (`getSession` + redirect)
- [ ] Nav difilter per role (`getNavForRole`) — UX, bukan satu-satunya keamanan
- [ ] Sidebar collapsible + responsive (mobile drawer bawaan shadcn)
- [ ] Active state nav akurat via `usePathname`
- [ ] Header sticky dengan trigger + breadcrumb + mode toggle
- [ ] Logout menghapus sesi + `router.refresh()`
- [ ] Dark mode & keyboard nav terverifikasi
