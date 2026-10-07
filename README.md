# Four controlled NACA0012 cases in SU2

This project contains four two-dimensional SU2 v8.5.0 cases. They use the **same airfoil mesh, Mach number, angle of attack, temperature, speed, numerical settings where applicable, and iteration limits**. The two Euler cases share one free-stream pressure, and the two laminar Navier–Stokes cases share a Reynolds number. The model differences are viscosity, steady versus unsteady flow, and the imposed disturbance: airfoil plunge or incoming sine gust.

## Shared baseline

| Quantity | Value |
| --- | --- |
| Airfoil | NACA0012, chord $c=1$ m, from $x=0$ to $x=1$ m |
| Computational domain | Circular far field of approximately 20 m radius, centered at $(0,0)$ |
| Mesh | [mesh_NACA0012_common.su2](mesh_NACA0012_common.su2): 8,741 points and 13,156 elements; used by all four configurations |
| Free-stream Mach number | $M_\infty=0.2$ |
| Free-stream angle of attack | $\alpha=0^\circ$ |
| Free-stream temperature | $T_\infty=288.15$ K |
| Gas model | Ideal gas, $\gamma=1.4$, $R=287.058\ \mathrm{J/(kg\,K)}$ |
| Free-stream speed | $U_\infty=M_\infty\sqrt{\gamma RT_\infty}=68.0594$ m/s, directed along $+x$ |
| Euler cases 1 and 4: pressure and density | $p_\infty=101325$ Pa; $\rho_\infty\approx1.22498\ \mathrm{kg/m^3}$ |
| Navier–Stokes cases 2 and 3: pressure and density | $p_\infty\approx21.7462$ Pa; $\rho_\infty\approx2.6290\times10^{-4}\ \mathrm{kg/m^3}$, derived from $Re_c=1000$ |
| Reynolds number | $Re_c=\rho_\infty U_\infty c/\mu_\infty=1000$ in the two viscous cases |
| Viscosity at $T_\infty$ | $\mu_\infty\approx1.7893\times10^{-5}\ \mathrm{Pa\,s}$, using SU2's default Sutherland air model |
| Initial solution | Uniform free-stream flow, with no restart file read |

At the specified Mach number, temperature, 1 m chord, and Sutherland air viscosity, prescribing $Re_c=1000$ determines the low pressure and density in cases 2 and 3. The Euler equations have no viscosity term; cases 1 and 4 instead use 101325 Pa and do not take a Reynolds-number input. Thus the Euler and Navier–Stokes cases **do not have identical dimensional free-stream states**. The low-Re laminar cases are numerical examples, not atmospheric-pressure airfoil predictions.

The airfoil and circular far field are defined by the mesh coordinates, not by a geometry-generation script in this project. The mesh boundary markers are <code>airfoil</code> and <code>farfield</code>. All four configurations point to the single shared mesh at <code>../mesh_NACA0012_common.su2</code>. Older case-specific meshes in the original local folder are **not** read by these configurations or required to run them.

## Four cases

| Case | Equation and wall condition | Viscosity | Physical time | Disturbance | Iteration limit |
| --- | --- | --- | --- | --- | --- |
| [1. Steady Euler](1_NACA0012_Euler/inv_NACA0012.cfg) | Compressible Euler; fixed slip wall | No | Steady | None | 1,000 steady iterations |
| [2. Steady laminar Navier–Stokes](2_NACA0012_Laminar/lam_NACA0012.cfg) | Compressible Navier–Stokes; fixed no-slip, adiabatic wall | Yes, laminar; no turbulence model | Steady | None | 1,000 steady iterations |
| [3. Unsteady laminar Navier–Stokes with plunge](3_NACA0012_Unsteady/plunging_NACA0012.cfg) | Compressible Navier–Stokes; moving no-slip, adiabatic wall | Yes, laminar; no turbulence model | Unsteady | Prescribed vertical airfoil translation | 250 physical steps, at most 50 inner iterations each |
| [4. Unsteady Euler with sine gust](4_NACA0012_SinWind/inv_gust_NACA0012.cfg) | Compressible Euler; fixed slip wall | No | Unsteady | Prescribed vertical gust in the flow | 250 physical steps, at most 50 inner iterations each |

All four cases use Roe convective fluxes, MUSCL reconstruction, the Venkatakrishnan limiter, weighted least-squares gradients, implicit Euler pseudo-time integration, CFL 1.0, and the same linear-solver and multigrid settings. The two unsteady cases use second-order dual-time stepping with the **same** physical step $\Delta t=0.0023555025613149587$ s and nominal duration $250\Delta t=0.5888756403$ s. Steady iterations are numerical convergence iterations, not physical seconds.

Cases 1 and 2 illustrate the change from inviscid to laminar viscous equations at a fixed airfoil, but their free-stream pressure and density differ. Cases 1 and 4 share the Euler free-stream state and compare a steady calculation with an unsteady gust calculation. Cases 2 and 3 share the laminar free-stream state and compare a steady calculation with an unsteady plunge calculation. The latter two comparisons change both time dependence and forcing, so they do not isolate time dependence alone.

### Governing equations

Let $\mathbf U=(\rho,\rho\mathbf u,\rho E)^\mathsf T$. The compressible Navier–Stokes equations are

$$
\frac{\partial\mathbf U}{\partial t}
+\nabla\cdot\mathbf F_c
=\nabla\cdot\mathbf F_v,
\qquad
\mathbf F_c=
\begin{pmatrix}
\rho\mathbf u\\
\rho\mathbf u\otimes\mathbf u+p\mathbf I\\
(\rho E+p)\mathbf u
\end{pmatrix},
\qquad
\mathbf F_v=
\begin{pmatrix}
0\\
\boldsymbol\tau\\
\boldsymbol\tau\cdot\mathbf u-\mathbf q
\end{pmatrix},
$$

where $\boldsymbol\tau=\mu[\nabla\mathbf u+(\nabla\mathbf u)^\mathsf T-\frac23(\nabla\cdot\mathbf u)\mathbf I]$, $\mathbf q=-k\nabla T$, and $p=\rho RT$. The Euler equations set $\mathbf F_v=0$. Case 1 solves steady Euler, $\nabla\cdot\mathbf F_c=0$; case 2 solves steady Navier–Stokes, $\nabla\cdot\mathbf F_c=\nabla\cdot\mathbf F_v$.

Case 3 retains the physical time derivative and uses a moving mesh. In integral form,

$$
\frac{\mathrm d}{\mathrm dt}\int_{\Omega(t)}\mathbf U\,\mathrm d\Omega
+\int_{\partial\Omega(t)}
(\mathbf F_c-\mathbf U\otimes\mathbf v_g-\mathbf F_v)\cdot\mathbf n\,\mathrm dS=0,
$$

where $\mathbf v_g$ is grid velocity. Its prescribed rigid plunge is

$$
y(t)-y(0)=-0.0222748080\sin(106.69842\,t)\ {\rm m}.
$$

The peak vertical wall speed is $A\omega=2.37668682$ m/s, corresponding to $\arctan(A\omega/U_\infty)\approx2^\circ$. This is **forced motion** specified in the configuration, not free structural vibration or two-way fluid–structure interaction. One plunge period is about 0.05889 s, so the 250-step interval covers approximately ten periods.

SU2's <code>RIGID_MOTION</code> setting translates the **entire mesh**, including its far-field boundary, with the airfoil. Thus all cases start from the same mesh, but case 3's computational domain moves during the run.

Case 4 solves the unsteady Euler equations, $\partial_t\mathbf U+\nabla\cdot\mathbf F_c=0$, with a **fixed airfoil**. SU2 applies the gust through its field-velocity method. With

$$
\xi=\frac{x-x_0-U_\infty(t-t_0)}{L},\qquad
w_g(x,t)=
\begin{cases}
A_g\sin(2\pi\xi),&0<\xi<N,\\
0,&\text{otherwise},
\end{cases}
$$

the settings are $x_0=-25$ m, $t_0=0$ s, $L=25$ m, $N=1$, and $A_g=2.37668682$ m/s. The gust travels in $+x$ at $U_\infty$. Its peak vertical speed also gives $\arctan(A_g/U_\infty)\approx2^\circ$. The gust is represented by an effective negative grid velocity in the flux computation; the physical airfoil does not plunge.

### Initial and boundary conditions

All four configurations set <code>RESTART_SOL= NO</code>. Each initial fluid solution is its uniform free-stream state in the table above. Cases 1 and 4 explicitly set $p_\infty=101325$ Pa. In cases 2 and 3, <code>INIT_OPTION= REYNOLDS</code> makes SU2 compute $p_\infty\approx21.7462$ Pa from $Re_c=1000$, Sutherland viscosity, and $T_\infty$. The inviscid walls are impermeable slip walls. The viscous walls are no-slip and have zero prescribed heat flux. The outer boundary uses the <code>farfield</code> marker.

For case 3, the airfoil's plunge displacement is zero at $t=0$, while its prescribed velocity is nonzero. For case 4, the gust begins at $t=0$ over $-25<x<0$ m; the initial uniform flow is then advanced with that upstream gust field active. No case reads the old <code>restart_flow*.dat</code> files.

## Student quick start: install once, then run the cases

For this class, the easiest route is:

1. install the **precompiled serial version of SU2**;
2. install **ParaView** for flow-field visualization;
3. download this repository;
4. run each case with <code>SU2_CFD</code> from its case folder;
5. open the generated <code>.vtu</code> files in ParaView.

You do **not** need MPI, RANS, SU2GUI, a compiler, or a source build for these teaching cases.

Official links:

- [SU2 download page](https://su2code.github.io/download.html)
- [SU2 macOS/Linux installation guide](https://su2code.github.io/docs_v7/SU2-Linux-MacOS/)
- [SU2 Windows installation guide](https://su2code.github.io/docs_v7/SU2-Windows/)
- [ParaView download](https://www.paraview.org/download/)

### A. Install SU2 on macOS

#### 1. Download SU2

Go to the [official SU2 download page](https://su2code.github.io/download.html) and download the **serial** package labeled **SU2 for macOS**.

For these 2-D classroom cases, do not choose the MPI version.

Unzip the archive to a simple location, for example:

~~~text
~/SU2/
~~~

Find the directory that contains the executable:

~~~text
SU2_CFD
~~~

For example, the path may look like:

~~~text
/Users/yourname/SU2/bin
~~~

The exact path depends on where you unpacked SU2.

#### 2. Add SU2 to the macOS PATH

macOS normally uses the zsh shell. Open Terminal and edit:

~~~bash
nano ~/.zshrc
~~~

Add the following lines, replacing the example path with the directory that actually contains <code>SU2_CFD</code>:

~~~bash
export SU2_RUN="/Users/yourname/SU2/bin"
export PATH="$SU2_RUN:$PATH"
export PYTHONPATH="$SU2_RUN:$PYTHONPATH"
~~~

Save the file, then reload it:

~~~bash
source ~/.zshrc
~~~

Verify the installation:

~~~bash
which SU2_CFD
SU2_CFD
~~~

<code>which SU2_CFD</code> should print the path to the executable.

If running <code>SU2_CFD</code> by itself prints an error such as:

~~~text
The configuration file (.cfg) is missing!!
~~~

that is actually a good sign: SU2 has started successfully and is only telling you that no case file was supplied.

#### 3. macOS security warning

The first time you run a downloaded SU2 binary, macOS may display:

~~~text
Apple could not verify "SU2_CFD" is free of malware...
~~~

If you downloaded SU2 from the official SU2 website or official <code>su2code</code> GitHub repository:

1. click **Done**;
2. open **System Settings -> Privacy & Security**;
3. scroll to the Security section;
4. click **Open Anyway** for <code>SU2_CFD</code>;
5. confirm that you want to open it;
6. return to Terminal and run <code>SU2_CFD</code> again.

Do not disable Gatekeeper globally.

---

### B. Install SU2 on Windows — recommended student method

The Windows setup is very similar to macOS. The main difference is that Windows uses the **Environment Variables** control panel instead of <code>~/.zshrc</code>.

For this class, use the **precompiled serial Windows binary**. You do not need to compile SU2 from source and you do not need Microsoft MPI.

#### 1. Download the official Windows binary

Open the [official SU2 download page](https://su2code.github.io/download.html).

Under **Binary Executables**, download:

~~~text
SU2 for Windows
~~~

Do **not** choose <code>SU2 MPI for Windows</code> for this class.

Unzip the downloaded archive to a simple directory. A recommended location is:

~~~text
C:\SU2
~~~

Avoid directories with unnecessary spaces or non-ASCII characters if possible.

Open the extracted folder and find the directory containing:

~~~text
SU2_CFD.exe
~~~

That directory is the SU2 executable directory. For example, depending on the archive layout, it may be something like:

~~~text
C:\SU2\bin
~~~

Use the path that actually contains <code>SU2_CFD.exe</code> on your computer.

#### 2. Add <code>SU2_RUN</code> and SU2 to <code>Path</code>

In Windows:

~~~text
Start
-> search "environment variables"
-> Edit the system environment variables
-> Environment Variables
~~~

Under **User variables** (recommended for student computers), click **New** and create:

~~~text
Variable name:  SU2_RUN
Variable value: C:\SU2\bin
~~~

Replace <code>C:\SU2\bin</code> with the real directory containing <code>SU2_CFD.exe</code>.

Then select the user variable named <code>Path</code>:

~~~text
Path
-> Edit
-> New
-> add the same SU2 executable directory
~~~

For example:

~~~text
C:\SU2\bin
~~~

Click **OK** until all dialogs are closed.

Important: close any Command Prompt windows that were already open, then open a **new** Command Prompt so that the updated environment variables are loaded.

#### 3. Verify SU2

Open **Command Prompt (cmd.exe)** and type:

~~~bat
echo %SU2_RUN%
where SU2_CFD
SU2_CFD
~~~

A successful setup should behave as follows:

- <code>echo %SU2_RUN%</code> prints your SU2 executable directory;
- <code>where SU2_CFD</code> prints the full path to <code>SU2_CFD.exe</code>;
- <code>SU2_CFD</code> starts SU2.

If the final command prints:

~~~text
The configuration file (.cfg) is missing!!
~~~

that means **SU2 is installed correctly**. The solver is simply waiting for a case configuration file.

The official Windows installation guide describes the same <code>SU2_RUN</code> and <code>Path</code> setup. SU2 also supports MPI on Windows, but MPI is optional and is not needed for these 2-D teaching cases.

#### 4. Download this project on Windows

The easiest method for students is to use the GitHub ZIP download.

On this repository page:

~~~text
Code -> Download ZIP
~~~

Extract the ZIP to a simple location, for example:

~~~text
C:\Users\YourName\Documents\SU2-NACA0012-Four-Cases
~~~

Keep the folder structure unchanged because every <code>.cfg</code> file expects the shared mesh at:

~~~text
..\mesh_NACA0012_common.su2
~~~

You should see:

~~~text
SU2-NACA0012-Four-Cases
|
|-- mesh_NACA0012_common.su2
|-- 1_NACA0012_Euler
|-- 2_NACA0012_Laminar
|-- 3_NACA0012_Unsteady
|-- 4_NACA0012_SinWind
\-- README.md
~~~

#### 5. Run the four cases from Windows Command Prompt

Open **Command Prompt**.

Move to the project directory. The <code>/d</code> option also allows CMD to change drive letters if necessary:

~~~bat
cd /d "C:\Users\YourName\Documents\SU2-NACA0012-Four-Cases"
~~~

Replace the path with the location where you extracted the repository.

Run **Case 1 — steady Euler**:

~~~bat
cd 1_NACA0012_Euler
SU2_CFD inv_NACA0012.cfg
cd ..
~~~

Run **Case 2 — steady laminar Navier-Stokes**:

~~~bat
cd 2_NACA0012_Laminar
SU2_CFD lam_NACA0012.cfg
cd ..
~~~

Run **Case 3 — unsteady plunging laminar Navier-Stokes**:

~~~bat
cd 3_NACA0012_Unsteady
SU2_CFD plunging_NACA0012.cfg
cd ..
~~~

Run **Case 4 — unsteady Euler with sine gust**:

~~~bat
cd 4_NACA0012_SinWind
SU2_CFD inv_gust_NACA0012.cfg
cd ..
~~~

Always run each configuration **from inside its case folder**. The configuration uses:

~~~text
MESH_FILENAME= ../mesh_NACA0012_common.su2
~~~

so running from a different working directory may cause a mesh-file-not-found error.

#### 6. What successful execution looks like

When a case starts correctly, SU2 will print information about:

~~~text
mesh
solver
boundary markers
iterations / time iterations
residuals
lift
drag
~~~

For the steady cases, you will see numerical iterations until the steady solution is reached.

For the unsteady cases, you will see both:

~~~text
TIME_ITER
INNER_ITER
~~~

where <code>TIME_ITER</code> is the physical-time step and <code>INNER_ITER</code> is the numerical iteration used inside each physical-time step.

The output files are written into the corresponding case directory.

---

## Install ParaView

Download ParaView from the [official ParaView website](https://www.paraview.org/download/) and install the version for your operating system.

ParaView is used only for post-processing. It opens the <code>.vtu</code> files produced by SU2 and can display pressure, Mach number, density, velocity, and other flow variables.

---

## Download this teaching repository

### Easiest method: Download ZIP

On this GitHub page, click:

~~~text
Code -> Download ZIP
~~~

Unzip the folder and keep the directory structure unchanged.

The shared mesh is located at:

~~~text
mesh_NACA0012_common.su2
~~~

Each configuration uses the relative path:

~~~text
../mesh_NACA0012_common.su2
~~~

so do not move the <code>.cfg</code> files away from their case folders unless you also update <code>MESH_FILENAME</code>.

### Alternative: Git

~~~bash
git clone https://github.com/yonghyan/SU2-NACA0012-Four-Cases.git
cd SU2-NACA0012-Four-Cases
~~~

---

## Run the four teaching cases

Open Terminal on macOS/Linux or Command Prompt on Windows in the repository root. Each case should be run from its own case folder because the configuration files use a relative path to the shared mesh.

### macOS/Linux

~~~bash
# Case 1: steady Euler
(cd 1_NACA0012_Euler && SU2_CFD inv_NACA0012.cfg)

# Case 2: steady laminar Navier-Stokes
(cd 2_NACA0012_Laminar && SU2_CFD lam_NACA0012.cfg)

# Case 3: unsteady laminar Navier-Stokes with plunge
(cd 3_NACA0012_Unsteady && SU2_CFD plunging_NACA0012.cfg)

# Case 4: unsteady Euler with sine gust
(cd 4_NACA0012_SinWind && SU2_CFD inv_gust_NACA0012.cfg)
~~~

### Windows Command Prompt

Enter the chosen case directory first. For example:

~~~bat
cd 1_NACA0012_Euler
SU2_CFD inv_NACA0012.cfg
~~~

Then return to the repository root before entering another case directory.

---

## Output files

The active configurations write files with these prefixes:

~~~text
history_unified.csv
flow_unified*.vtu
surface_flow_unified*.vtu
restart_flow_unified*.dat
~~~

### Steady cases

The main result is the final converged flow field.

Typical outputs include:

- lift coefficient, <code>CL</code>;
- drag coefficient, <code>CD</code>;
- pressure and Mach-number fields;
- surface-flow data.

### Unsteady cases

A sequence of flow fields is written every ten physical-time steps.

In ParaView:

1. select the <code>flow_unified*.vtu</code> files;
2. open them as a file series;
3. click **Apply**;
4. use the Play button to view the transient flow.

The history file can also be used to examine quantities such as <code>CL(t)</code> and <code>CD(t)</code>.

---

## Common problems

### <code>SU2_CFD: command not found</code>

SU2 is not on the system <code>PATH</code>. Recheck <code>SU2_RUN</code> and <code>PATH</code>, then open a new terminal.

### <code>The configuration file (.cfg) is missing!!</code>

If this appears after typing only:

~~~text
SU2_CFD
~~~

the executable is working. You simply need to provide a configuration file, for example:

~~~text
SU2_CFD inv_NACA0012.cfg
~~~

### Mesh file cannot be found

The configurations expect:

~~~text
../mesh_NACA0012_common.su2
~~~

Keep the repository folder structure unchanged, or update <code>MESH_FILENAME</code>.

### macOS says that Apple cannot verify <code>SU2_CFD</code>

If SU2 came from the official SU2 source, use:

~~~text
System Settings -> Privacy & Security -> Open Anyway
~~~

Do not disable macOS security globally.

---

## What students should remember

For this project:

- <code>.su2</code> = computational mesh and boundary-marker names;
- <code>.cfg</code> = physics, boundary conditions, numerical settings, time settings, and output settings;
- <code>SU2_CFD</code> = the CFD solver;
- <code>ParaView</code> = post-processing and visualization.

The basic workflow is:

~~~text
Choose a case folder
   ->
Read / modify the .cfg file
   ->
Run: SU2_CFD case.cfg
   ->
Check the terminal output and history CSV
   ->
Open VTU results in ParaView
~~~

