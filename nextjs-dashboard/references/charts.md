# Charts & KPI Cards

Visualisasi data dashboard pakai shadcn **Chart** (wrapper Recharts) + **KPI card**. Warna dari token `--chart-1..5` → konsisten light/dark, bukan warna random.

Butuh: `pnpm dlx shadcn@latest add chart card` · Recharts ikut ter-install.

---

## 1. KPI / Stat Card

```tsx
// src/components/dashboard/stat-card.tsx
import { ArrowDownRight, ArrowUpRight, type LucideIcon } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { cn } from "@/lib/utils";

interface StatCardProps {
  title: string;
  value: string;
  delta?: number; // persen; + naik, - turun
  icon?: LucideIcon;
}

export function StatCard({ title, value, delta, icon: Icon }: StatCardProps) {
  const up = (delta ?? 0) >= 0;
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">{title}</CardTitle>
        {Icon && <Icon className="size-4 text-muted-foreground" />}
      </CardHeader>
      <CardContent>
        <div className="text-2xl font-semibold tracking-tight">{value}</div>
        {delta !== undefined && (
          <p className={cn("mt-1 flex items-center gap-1 text-xs", up ? "text-emerald-600 dark:text-emerald-400" : "text-destructive")}>
            {up ? <ArrowUpRight className="size-3.5" /> : <ArrowDownRight className="size-3.5" />}
            {Math.abs(delta)}% dari bulan lalu
          </p>
        )}
      </CardContent>
    </Card>
  );
}
```

Grid KPI:

```tsx
<div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
  <StatCard title="Total Pendapatan" value="Rp 45,2 jt" delta={12.5} icon={Wallet} />
  <StatCard title="Pengguna Aktif" value="2.340" delta={4.1} icon={Users} />
  <StatCard title="Transaksi" value="1.129" delta={-2.3} icon={Receipt} />
  <StatCard title="Konversi" value="3,6%" delta={0.8} icon={TrendingUp} />
</div>
```

> Warna status delta (emerald/destructive) hanya untuk **makna** naik/turun — bukan dekorasi.

---

## 2. Area Chart (shadcn Chart + Recharts)

```tsx
// src/components/dashboard/revenue-chart.tsx
"use client";

import { Area, AreaChart, CartesianGrid, XAxis } from "recharts";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  ChartContainer, ChartTooltip, ChartTooltipContent, type ChartConfig,
} from "@/components/ui/chart";

const data = [
  { month: "Jan", revenue: 1860 },
  { month: "Feb", revenue: 3050 },
  { month: "Mar", revenue: 2370 },
  { month: "Apr", revenue: 2730 },
  { month: "Mei", revenue: 2090 },
  { month: "Jun", revenue: 3140 },
];

// Warna dari token — no hardcode
const chartConfig = {
  revenue: { label: "Pendapatan", color: "var(--chart-1)" },
} satisfies ChartConfig;

export function RevenueChart() {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Pendapatan 6 bulan</CardTitle>
      </CardHeader>
      <CardContent>
        <ChartContainer config={chartConfig} className="aspect-[16/6] w-full">
          <AreaChart data={data} margin={{ left: 12, right: 12 }}>
            <CartesianGrid vertical={false} />
            <XAxis dataKey="month" tickLine={false} axisLine={false} tickMargin={8} />
            <ChartTooltip content={<ChartTooltipContent />} />
            <Area
              dataKey="revenue"
              type="natural"
              fill="var(--color-revenue)"
              fillOpacity={0.2}
              stroke="var(--color-revenue)"
              strokeWidth={2}
            />
          </AreaChart>
        </ChartContainer>
      </CardContent>
    </Card>
  );
}
```

Catatan (Tailwind v4 + shadcn):
- `ChartContainer` men-generate CSS var `--color-<key>` dari `chartConfig.color`.
- Warna langsung `var(--chart-1)` (tanpa `hsl()` wrapper — sudah oklch di token).
- `ChartTooltipContent` sudah dark-mode & a11y aware.

---

## 3. Layout dashboard overview

```tsx
// src/app/(app)/dashboard/page.tsx
import { StatCard } from "@/components/dashboard/stat-card";
import { RevenueChart } from "@/components/dashboard/revenue-chart";
import { Wallet, Users, Receipt, TrendingUp } from "lucide-react";

export default function DashboardPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">Dashboard</h1>
        <p className="text-sm text-muted-foreground">Ringkasan performa bisnis kamu.</p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard title="Total Pendapatan" value="Rp 45,2 jt" delta={12.5} icon={Wallet} />
        <StatCard title="Pengguna Aktif" value="2.340" delta={4.1} icon={Users} />
        <StatCard title="Transaksi" value="1.129" delta={-2.3} icon={Receipt} />
        <StatCard title="Konversi" value="3,6%" delta={0.8} icon={TrendingUp} />
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <RevenueChart />
        {/* chart lain */}
      </div>
    </div>
  );
}
```

---

## Checklist charts (wajib)

- [ ] Warna chart dari token `--chart-1..5` (nol hardcode hex)
- [ ] Chart client component; data fetch tetap via TanStack Query bila dinamis
- [ ] Loading (skeleton) & empty state untuk chart yang menunggu data
- [ ] KPI: warna delta hanya untuk makna naik/turun
- [ ] Chart responsive (`aspect-*` + `w-full`), terbaca di mobile
- [ ] Dark mode & kontras terverifikasi
